import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../shared/services/firebase_service.dart';
import '../../automation/widgets/context_tag_chip.dart';

class PendingRuleCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const PendingRuleCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final id          = item['id']                  as String;
    final description = item['pattern_description'] as String? ?? '';
    final confidence  = (item['confidence']         as num?)?.toDouble() ?? 0;
    final sampleCount = item['sample_count']        as int? ?? 0;
    final suggested   = item['suggested_rule']      as Map<dynamic,dynamic>? ?? {};
    final rawTags     = suggested['context_tags'];
    final tags = rawTags is List ? rawTags.cast<String>() : <String>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purpleLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.purpleLight, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.auto_awesome, size: 16, color: AppColors.aiPurple),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('New pattern discovered',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(20)),
                child: Text('${(confidence * 100).toInt()}% match',
                    style: const TextStyle(fontSize: 11, color: AppColors.greenDark, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          Text('Based on $sampleCount observations',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, children: tags.map((t) => ContextTagChip(tag: t)).toList()),
          ],
          const SizedBox(height: 14),
          // Actions
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => FirebaseService.rejectInboxRule(id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Dismiss'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => FirebaseService.approveInboxRule(
                    id, Map<String, dynamic>.from(suggested)),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Add as rule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.aiPurple, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}