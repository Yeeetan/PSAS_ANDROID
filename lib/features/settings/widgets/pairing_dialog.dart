import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../shared/services/firebase_service.dart';

/// Shows a 30s pairing window (see main.py's PAIRING_WINDOW_SEC) and
/// reacts live to pairing_mode/{home}:
///   - active:true, no duplicate/found yet   -> searching, countdown
///   - active:true, duplicate_room set       -> banner, keeps listening
///   - active:false, found_device_id set     -> success
///   - active:false, nothing found           -> timeout
class PairingDialog extends ConsumerStatefulWidget {
  const PairingDialog({super.key});

  @override
  ConsumerState<PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends ConsumerState<PairingDialog> {
  Timer? _ticker;
  DateTime _now = DateTime.now();
  final _simulateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    FirebaseService.startPairing();
    // Local 1s ticker just to redraw the countdown ring/number -- the
    // actual window is enforced by main.py, this is purely cosmetic.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _simulateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pairingAsync = ref.watch(pairingModeProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: pairingAsync.when(
          loading: () => _loadingState(),
          error: (e, _) => _errorState('$e'),
          data: (data) {
            if (data == null || data['started_at'] == null) {
              return _loadingState();
            }

            final startedAt = DateTime.fromMillisecondsSinceEpoch(
                (data['started_at'] as int) * 1000);
            final elapsed = _now.difference(startedAt).inSeconds;
            final remaining = (30 - elapsed).clamp(0, 30);
            final active = data['active'] == true;

            if (active) {
              return _searchingState(
                remaining: remaining,
                duplicateRoom: data['duplicate_room'] as String?,
              );
            }

            final foundDeviceId = data['found_device_id'] as String?;
            if (foundDeviceId != null) {
              return _successState(
                room: (data['found_room'] as String?) ?? foundDeviceId,
              );
            }

            return _timeoutState();
          },
        ),
      ),
    );
  }

  // ── UI states ──────────────────────────────────────────

  Widget _loadingState() => const SizedBox(
    height: 160,
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _errorState(String message) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.error_outline_rounded,
          color: AppColors.error, size: 40),
      const SizedBox(height: 12),
      Text(message, style: const TextStyle(fontSize: 12)),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );

  Widget _searchingState({required int remaining, String? duplicateRoom}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.wifi_tethering_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text('Looking for a new switch…',
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Power on the new wall node, or hold its Pair button, now.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: remaining / 30,
                  strokeWidth: 5,
                  backgroundColor: AppColors.border,
                ),
              ),
              Text('${remaining}s',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (duplicateRoom != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amberLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 18, color: AppColors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "'$duplicateRoom' is already paired. Still listening…",
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.amber),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'No spare hardware? Simulate a new node powering on:',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _simulateController,
                decoration: const InputDecoration(
                  hintText: 'e.g. GuestRoom',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final room = _simulateController.text.trim();
                if (room.isNotEmpty) {
                  FirebaseService.simulateHello(room);
                  _simulateController.clear();
                }
              },
              child: const Text('Simulate'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            FirebaseService.cancelPairing();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _successState({required String room}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded,
            color: AppColors.greenDark, size: 48),
        const SizedBox(height: 12),
        Text('Found: $room Switch',
            style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text(
          'It has been added to your devices. Place it on your floor '
              'plan to finish setup.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }

  Widget _timeoutState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.search_off_rounded,
            color: AppColors.textSecondary, size: 48),
        const SizedBox(height: 12),
        const Text('No new device found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text(
          'The pairing window closed after about 30 seconds without '
              'finding a new switch.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => FirebaseService.startPairing(),
                child: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}