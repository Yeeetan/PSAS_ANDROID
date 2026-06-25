//D:\CODES\PSAS_ANDROID\lib\features\automation\widgets\context_tag_chip.dart
import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class ContextTagChip extends StatelessWidget {
  final String tag;
  const ContextTagChip({super.key, required this.tag});

  ({Color bg, Color fg, IconData icon}) get _style {
    switch (tag.toLowerCase()) {
      case 'morning':   return (bg: AppColors.amberLight, fg: AppColors.amber, icon: Icons.wb_sunny_outlined);
      case 'afternoon': return (bg: const Color(0xFFFAEEDA), fg: const Color(0xFF854F0B), icon: Icons.wb_cloudy_outlined);
      case 'night':     return (bg: AppColors.purpleLight, fg: AppColors.aiPurple, icon: Icons.nights_stay_outlined);
      case 'weekday':   return (bg: AppColors.greenLight, fg: AppColors.greenDark, icon: Icons.calendar_today_outlined);
      case 'weekend':   return (bg: AppColors.purpleLight, fg: AppColors.aiPurple, icon: Icons.weekend_outlined);
      case 'holiday':   return (bg: AppColors.amberLight, fg: AppColors.amber, icon: Icons.celebration_outlined);
      case 'rainy':     return (bg: AppColors.blueLight, fg: AppColors.blueDark, icon: Icons.water_drop_outlined);
      default:          return (bg: const Color(0xFFF1EFE8), fg: AppColors.textSecondary, icon: Icons.label_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 12, color: s.fg),
          const SizedBox(width: 4),
          Text(tag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: s.fg)),
        ],
      ),
    );
  }
}