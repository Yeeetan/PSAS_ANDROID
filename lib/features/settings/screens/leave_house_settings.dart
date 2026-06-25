import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/firebase_service.dart';
import '../../../app/theme.dart';

class LeaveHouseSettingsScreen extends ConsumerWidget {
  const LeaveHouseSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices    = ref.watch(devicesProvider).valueOrNull ?? [];
    final exclusions = ref.watch(leaveHouseExclusionsProvider).valueOrNull ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        title: const Text('Leave House Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.greenDark, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Excluded devices stay ON and keep their '
                        'routine when you press Leave House. '
                        'Useful for outdoor lights or security devices.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section label
          const Text(
            'DEVICES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),

          // Device toggle list
          if (devices.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No devices found.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ...devices.map((device) {
              final isExcluded = exclusions[device.room] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isExcluded
                        ? AppColors.primary
                        : AppColors.border,
                    width: isExcluded ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isExcluded
                            ? AppColors.greenLight
                            : const Color(0xFFF1EFE8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isExcluded
                            ? Icons.lock_open_rounded
                            : Icons.power_off_rounded,
                        size: 18,
                        color: isExcluded
                            ? AppColors.greenDark
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name + status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isExcluded
                                ? 'Stays ON when leaving'
                                : 'Turns OFF when leaving',
                            style: TextStyle(
                              fontSize: 12,
                              color: isExcluded
                                  ? AppColors.greenDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Toggle
                    Switch(
                      value: isExcluded,
                      onChanged: (val) =>
                          FirebaseService.setLeaveHouseExclusion(
                              device.room, val),
                      activeColor: AppColors.primary,
                      materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),

          // Preview card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'When you press Leave House:',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                if (devices.isEmpty)
                  const Text('No devices.',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary))
                else
                  ...devices.map((device) {
                    final isExcluded =
                        exclusions[device.room] == true;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            isExcluded
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                            size: 16,
                            color: isExcluded
                                ? AppColors.greenDark
                                : AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${device.name}  —  '
                                  '${isExcluded ? "stays ON (excluded)" : "turns OFF"}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isExcluded
                                    ? AppColors.greenDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}