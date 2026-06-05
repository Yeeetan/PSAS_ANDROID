import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../shared/services/firebase_service.dart';
import '../../../shared/widgets/device_toggle_card.dart';
import '../models/pin_model.dart';

class DeviceBottomSheet extends ConsumerWidget {
  final PinModel pin;
  const DeviceBottomSheet({super.key, required this.pin});

  static void show(BuildContext context, PinModel pin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProviderScope.containerOf(context, listen: false)
          .read(devicesProvider) // keeps providers alive inside the sheet
          .when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (_) => DeviceBottomSheet(pin: pin),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.home_outlined, size: 18, color: AppColors.greenDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pin.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text('${pin.linkedDeviceIds.length} device(s)',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(),
          // Device list
          Flexible(
            child: devicesAsync.maybeWhen(
              data: (all) {
                final pinDevices = all.where((d) => pin.linkedDeviceIds.contains(d.id)).toList();
                if (pinDevices.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No devices linked to this pin.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: pinDevices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => DeviceToggleCard(device: pinDevices[i], compact: true),
                );
              },
              orElse: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}