//D:\CODES\PSAS_ANDROID\lib\features\automation\widgets\timeline_strip.dart
import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../models/routine_model.dart';

class TimelineStrip extends StatelessWidget {
  final List<RoutineAction> actions;
  final String baseTime;
  const TimelineStrip({super.key, required this.actions, required this.baseTime});

  String _timeAt(int offsetSeconds) {
    final parts = baseTime.split(':');
    final base  = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final total = base + offsetSeconds ~/ 60;
    final h = (total ~/ 60 % 24).toString().padLeft(2, '0');
    final m = (total % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actions.asMap().entries.expand((e) {
          final action = e.value;
          final isOn = action.state == 'ON';
          final chip = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isOn ? AppColors.greenLight : const Color(0xFFF1EFE8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isOn ? AppColors.primary.withOpacity(0.3) : AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_timeAt(action.offsetSeconds),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                        color: isOn ? AppColors.greenDark : AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(action.deviceId.replaceFirst('dev_', '').replaceAll('_', ' '),
                    style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isOn ? AppColors.primary : AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(action.state,
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          );
          return e.key == 0
              ? [chip]
              : [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.textHint),
            ),
            chip,
          ];
        }).toList(),
      ),
    );
  }
}