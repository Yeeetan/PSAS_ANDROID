// floor_plan/screens/pin_placement_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/services/firebase_service.dart';
import '../models/pin_model.dart';
import '../widgets/floor_plan_viewer.dart';
import '../models/floor_model.dart';

class PinPlacementScreen extends ConsumerWidget {
  final String floorId;
  const PinPlacementScreen({super.key, required this.floorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final floors  = ref.watch(floorsProvider).valueOrNull ?? [];
    final devices = ref.watch(devicesProvider).valueOrNull ?? [];

    FloorModel? floor;
    try { floor = floors.firstWhere((f) => f.id == floorId); }
    catch (_) { floor = floors.isNotEmpty ? floors.first : null; }

    return Scaffold(
      appBar: AppBar(
        title: Text('Place pins — ${floor?.name ?? ''}'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.amberLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Edit mode',
                style: TextStyle(fontSize: 12, color: AppColors.amber, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      body: floor == null
          ? const Center(child: CircularProgressIndicator())
          : FloorPlanViewer(
        floor: floor,
        devices: devices,
        editMode: true,
        onLongPress: (xPct, yPct) => _dropPin(context, ref, xPct, yPct, devices),
        onPinDelete: (pin) => _deletePin(context, pin),
        onPinMoved: (pin, newX, newY) => _movePin(pin, newX, newY), // NEW
      ),
    );
  }

  // NEW: Update Firebase when the drag ends
  Future<void> _movePin(PinModel pin, double newX, double newY) async {
    final updatedMap = pin.toMap();
    updatedMap['x_pct'] = newX;
    updatedMap['y_pct'] = newY;
    await FirebaseService.upsertPin(floorId, pin.id, updatedMap);
  }

  Future<void> _dropPin(BuildContext context, WidgetRef ref,
      double xPct, double yPct, List devices) async {
    final labelCtrl = TextEditingController();
    final selectedIds = <String>{};

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('New pin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: labelCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Label', hintText: 'Bedroom'),
                ),
                const SizedBox(height: 14),
                const Text('Link devices',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                ...devices.map((d) => CheckboxListTile(
                  dense: true,
                  title: Text(d.name, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(d.id, style: const TextStyle(fontSize: 11)),
                  value: selectedIds.contains(d.id),
                  onChanged: (v) => setDs(() =>
                  v == true ? selectedIds.add(d.id) : selectedIds.remove(d.id)),
                  activeColor: AppColors.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (labelCtrl.text.trim().isEmpty) return;
                final pinId = 'pin_${DateTime.now().millisecondsSinceEpoch}';
                final pin = PinModel(
                  id: pinId, xPct: xPct, yPct: yPct,
                  label: labelCtrl.text.trim(),
                  linkedDeviceIds: selectedIds.toList(),
                );
                await FirebaseService.upsertPin(floorId, pinId, pin.toMap());
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save pin'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePin(BuildContext context, PinModel pin) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete pin?'),
        content: Text('Remove "${pin.label}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await FirebaseService.deletePin(floorId, pin.id);
  }
}