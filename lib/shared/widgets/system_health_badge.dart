import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/firebase_service.dart';
import '../../app/theme.dart';

class SystemHealthBadge extends ConsumerWidget {
  const SystemHealthBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heartbeat = ref.watch(hubHeartbeatProvider);

    return heartbeat.maybeWhen(
      data: (ts) {
        final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final isOnline = ts != null && (nowSec - ts) < 120; // 2-min threshold
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isOnline ? AppColors.greenLight : AppColors.redLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.greenDark : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isOnline ? 'Hub online' : 'Hub offline',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isOnline ? AppColors.greenDark : AppColors.error,
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}