//D:\CODES\PSAS_ANDROID\lib\features\automation\widgets\context_tag_chip.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/services/firebase_service.dart';
import '../models/routine_model.dart';
import 'context_tag_chip.dart';
import 'timeline_strip.dart';

class RoutineCard extends StatelessWidget {
  final RoutineModel routine;
  const RoutineCard({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: routine.isActive ? AppColors.border : AppColors.border.withOpacity(0.4)),
      ),
      child: Opacity(
        opacity: routine.isActive ? 1 : 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                if (routine.isAiGenerated)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.purpleLight, borderRadius: BorderRadius.circular(4)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 10, color: AppColors.aiPurple),
                        SizedBox(width: 3),
                        Text('AI', style: TextStyle(fontSize: 10, color: AppColors.aiPurple, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                Expanded(
                  child: Text(routine.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                Switch(
                  value: routine.isActive,
                  onChanged: (v) => FirebaseService.setRoutineStatus(routine.id, v),
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Time + fine-tune indicator
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(routine.effectiveTime,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                if (routine.aiAdjustedTime != null && routine.aiAdjustedTime != routine.baseTime)
                  Text(' (base ${routine.baseTime})',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                if (routine.aiFineTuneEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.purpleLight, borderRadius: BorderRadius.circular(4)),
                    child: const Text('AI fine-tune on',
                        style: TextStyle(fontSize: 10, color: AppColors.aiPurple)),
                  ),
              ],
            ),
            // Tags
            if (routine.contextTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6,
                  children: routine.contextTags.map((t) => ContextTagChip(tag: t)).toList()),
            ],
            // Timeline
            if (routine.actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              TimelineStrip(actions: routine.actions, baseTime: routine.effectiveTime),
            ],
            // Footer
            const SizedBox(height: 10),
            Row(
              children: [
                if (routine.confidence != null)
                  Text('${(routine.confidence! * 100).toInt()}% confidence',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                  onPressed: () => context.push('/routine-editor?id=${routine.id}'),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 14),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  onPressed: () => _confirmDelete(context),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete routine?'),
        content: Text('Delete "${routine.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await FirebaseService.deleteRoutine(routine.id);
  }
}