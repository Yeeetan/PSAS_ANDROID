import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../app/theme.dart';
import '../../../shared/services/firebase_service.dart';
import '../models/routine_model.dart';
import '../widgets/routine_card.dart';
import '../widgets/context_tag_chip.dart';

// ──────────────────────────────────────────────
// PROVIDERS
// ──────────────────────────────────────────────
final currentModeProvider = StreamProvider<String>((ref) {
  return FirebaseDatabase.instance
      .ref('homes/$kHomeId/current_mode')
      .onValue
      .map((e) => (e.snapshot.value as String?) ?? 'normal');
});

final offDaysProvider = StreamProvider<List<int>>((ref) {
  return FirebaseDatabase.instance
      .ref('homes/$kHomeId/off_days')
      .onValue
      .map((e) {
    final data = e.snapshot.value;
    if (data == null) return <int>[];
    if (data is List) return data.cast<int>();
    if (data is Map) return data.values.cast<int>().toList();
    return <int>[];
  });
});

final customCategoriesProvider = StreamProvider<List<String>>((ref) {
  return FirebaseDatabase.instance
      .ref('homes/$kHomeId/custom_categories')
      .onValue
      .map((e) {
    final data = e.snapshot.value;
    if (data == null) return <String>[];
    if (data is List) return data.cast<String>();
    if (data is Map) return data.values.cast<String>().toList();
    return <String>[];
  });
});

// ──────────────────────────────────────────────
// HELPERS
// ──────────────────────────────────────────────
String _autoDetectMode(List<int> offDays) {
  final today = DateTime.now().weekday - 1; // 0=Mon, 6=Sun
  return offDays.contains(today) ? 'holiday' : 'normal';
}

({Color bg, Color fg, Color dot, IconData icon, String label, String subtitle})
_modeStyle(String mode) {
  switch (mode) {
    case 'holiday':
      return (
      bg: AppColors.amberLight,
      fg: AppColors.amber,
      dot: AppColors.amber,
      icon: Icons.beach_access_rounded,
      label: 'Holiday',
      subtitle: 'Off-day routine active',
      );
    case 'special':
      return (
      bg: AppColors.redLight,
      fg: AppColors.error,
      dot: AppColors.error,
      icon: Icons.warning_amber_rounded,
      label: 'Special Mode',
      subtitle: 'Emergency / event override active',
      );
    default:
      return (
      bg: AppColors.greenLight,
      fg: AppColors.greenDark,
      dot: AppColors.primary,
      icon: Icons.wb_sunny_outlined,
      label: 'Normal Day',
      subtitle: 'Weekday routine active',
      );
  }
}

({Color bg, Color fg, IconData icon}) _categoryStyle(String category) {
  switch (category.toLowerCase()) {
    case 'holiday':
      return (bg: AppColors.amberLight, fg: AppColors.amber,     icon: Icons.beach_access_rounded);
    case 'special':
      return (bg: AppColors.redLight,   fg: AppColors.error,     icon: Icons.warning_amber_rounded);
    default:
      return (bg: AppColors.greenLight, fg: AppColors.greenDark, icon: Icons.wb_sunny_outlined);
  }
}

// ──────────────────────────────────────────────
// MAIN SCREEN
// ──────────────────────────────────────────────
class AutomationScreen extends ConsumerWidget {
  const AutomationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync         = ref.watch(routinesProvider);
    final currentModeAsync      = ref.watch(currentModeProvider);
    final offDaysAsync          = ref.watch(offDaysProvider);
    final customCategoriesAsync = ref.watch(customCategoriesProvider);

    final offDays     = offDaysAsync.valueOrNull ?? [];
    final autoMode    = _autoDetectMode(offDays);
    final currentMode = currentModeAsync.valueOrNull ?? autoMode;
    final customCats  = customCategoriesAsync.valueOrNull ?? [];
    final routines    = routinesAsync.valueOrNull ?? [];
    final style       = _modeStyle(currentMode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Brain'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New routine',
            onPressed: () => context.push('/routine-editor'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [

          // ── Current Mode Banner ──
          _ModeBanner(
            mode: currentMode,
            autoMode: autoMode,
            style: style,
            onTap: () => _showModeOverrideSheet(context, currentMode),
          ),
          const SizedBox(height: 20),

          // ── Off Days Setup prompt ──
          if (offDays.isEmpty) ...[
            _OffDaysPrompt(onTap: () => _showOffDaysSheet(context, offDays)),
            const SizedBox(height: 16),
          ],

          // ── Section header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CATEGORIES',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 1)),
              TextButton.icon(
                onPressed: () => _showAddCategoryDialog(context, customCats),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Normal Days ──
          _CategoryCard(
            category: 'normal',
            label: 'Normal Days',
            subtitle: 'Weekday routines',
            routineCount: routines
                .where((r) =>
            r.contextTags.contains('weekday') ||
                (!r.contextTags.contains('holiday') &&
                    !r.contextTags.contains('special') &&
                    !r.contextTags.contains('weekend')))
                .length,
            isActive: currentMode == 'normal',
            onTap: () =>
                _pushCategoryRoutines(context, 'normal', routines),
          ),
          const SizedBox(height: 8),

          // ── Holiday ──
          _CategoryCard(
            category: 'holiday',
            label: 'Holiday',
            subtitle: 'Off-day routines',
            routineCount: routines
                .where((r) =>
            r.contextTags.contains('holiday') ||
                r.contextTags.contains('weekend'))
                .length,
            isActive: currentMode == 'holiday',
            onTap: () =>
                _pushCategoryRoutines(context, 'holiday', routines),
          ),
          const SizedBox(height: 8),

          // ── Special ──
          _CategoryCard(
            category: 'special',
            label: 'Special',
            subtitle: 'Emergency / event routines',
            routineCount: routines
                .where((r) =>
            r.contextTags.contains('special') ||
                r.contextTags.contains('rainy'))
                .length,
            isActive: currentMode == 'special',
            onTap: () =>
                _pushCategoryRoutines(context, 'special', routines),
          ),

          // ── Custom Categories ──
          ...customCats.map((cat) {
            final count = routines
                .where(
                    (r) => r.contextTags.contains(cat.toLowerCase()))
                .length;
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _CategoryCard(
                category: cat.toLowerCase(),
                label: cat,
                subtitle: 'Custom category',
                routineCount: count,
                isActive: currentMode == cat.toLowerCase(),
                onTap: () => _pushCategoryRoutines(
                    context, cat.toLowerCase(), routines),
                onDelete: () =>
                    _deleteCustomCategory(context, cat, customCats),
              ),
            );
          }),

          const SizedBox(height: 24),

          // ── Off Days Summary ──
          if (offDays.isNotEmpty)
            _OffDaysSummary(
              offDays: offDays,
              onEdit: () => _showOffDaysSheet(context, offDays),
            ),
        ],
      ),
    );
  }

  void _showModeOverrideSheet(BuildContext context, String currentMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _ModeOverrideSheet(currentMode: currentMode),
    );
  }

  void _showOffDaysSheet(BuildContext context, List<int> current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _OffDaysSheet(current: current),
    );
  }

  void _showAddCategoryDialog(
      BuildContext context, List<String> existing) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'e.g. Vacation, Rainy season'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              final updated = [...existing, name];
              await FirebaseDatabase.instance
                  .ref('homes/$kHomeId/custom_categories')
                  .set(updated);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteCustomCategory(
      BuildContext context, String cat, List<String> all) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete category?'),
        content:
        Text('Delete "$cat"? Routines inside will not be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final updated = all.where((c) => c != cat).toList();
      await FirebaseDatabase.instance
          .ref('homes/$kHomeId/custom_categories')
          .set(updated);
    }
  }

  void _pushCategoryRoutines(BuildContext context, String category,
      List<RoutineModel> routines) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CategoryRoutinesScreen(
            category: category, routines: routines),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// MODE BANNER
// ──────────────────────────────────────────────
class _ModeBanner extends StatelessWidget {
  final String mode;
  final String autoMode;
  final ({Color bg, Color fg, Color dot, IconData icon, String label, String subtitle}) style;
  final VoidCallback onTap;

  const _ModeBanner({
    required this.mode,
    required this.autoMode,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOverridden = mode != autoMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: style.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: style.fg.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: style.fg.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(style.icon, color: style.fg, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                          color: style.dot, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('Currently: ${style.label}',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: style.fg)),
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    isOverridden
                        ? '${style.subtitle} · manually set'
                        : '${style.subtitle} · auto-detected',
                    style: TextStyle(
                        fontSize: 12,
                        color: style.fg.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: style.fg.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// MODE OVERRIDE BOTTOM SHEET
// ──────────────────────────────────────────────
class _ModeOverrideSheet extends StatelessWidget {
  final String currentMode;
  const _ModeOverrideSheet({required this.currentMode});

  @override
  Widget build(BuildContext context) {
    final modes = [
      ('normal',  'Normal Day',    'Weekday routine',            Icons.wb_sunny_outlined,      AppColors.greenDark),
      ('holiday', 'Holiday',       'Off-day routine',            Icons.beach_access_rounded,   AppColors.amber),
      ('special', 'Special Mode',  'Emergency / event override', Icons.warning_amber_rounded,  AppColors.error),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Switch mode',
              style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
            'Override the auto-detected mode. '
                'The system will use routines from the selected category.',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ...modes.map((m) {
            final isSelected = currentMode == m.$1;
            return GestureDetector(
              onTap: () async {
                await FirebaseDatabase.instance
                    .ref('homes/$kHomeId/current_mode')
                    .set(m.$1);
                if (context.mounted) Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? m.$5.withOpacity(0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? m.$5 : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(m.$4, color: m.$5, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.$2,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: m.$5)),
                          Text(m.$3,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded,
                          color: m.$5, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// CATEGORY CARD
// ──────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final String category;
  final String label;
  final String subtitle;
  final int routineCount;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _CategoryCard({
    required this.category,
    required this.label,
    required this.subtitle,
    required this.routineCount,
    required this.isActive,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = _categoryStyle(category);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? s.fg : AppColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: s.bg,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(s.icon, color: s.fg, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: s.bg,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text('Active',
                            style: TextStyle(
                                fontSize: 10,
                                color: s.fg,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ]),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(
              '$routineCount routine${routineCount != 1 ? 's' : ''}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 4),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 16, color: AppColors.error),
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// OFF DAYS PROMPT
// ──────────────────────────────────────────────
class _OffDaysPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _OffDaysPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.blueLight,
          borderRadius: BorderRadius.circular(12),
          border:
          Border.all(color: AppColors.blueDark.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined,
                color: AppColors.blueDark, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Set your off days so the app can auto-detect Holiday mode.',
                style:
                TextStyle(fontSize: 13, color: AppColors.blueDark),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.blueDark, size: 18),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// OFF DAYS BOTTOM SHEET
// ──────────────────────────────────────────────
class _OffDaysSheet extends StatefulWidget {
  final List<int> current;
  const _OffDaysSheet({required this.current});

  @override
  State<_OffDaysSheet> createState() => _OffDaysSheetState();
}

class _OffDaysSheetState extends State<_OffDaysSheet> {
  late List<int> _selected;
  final _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.current);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Set off days',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
            'The app will auto-switch to Holiday mode on these days.',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (i) {
              final selected = _selected.contains(i);
              return GestureDetector(
                onTap: () => setState(() =>
                selected ? _selected.remove(i) : _selected.add(i)),
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : const Color(0xFFF1EFE8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(_days[i],
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary)),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await FirebaseDatabase.instance
                    .ref('homes/$kHomeId/off_days')
                    .set(_selected);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// OFF DAYS SUMMARY
// ──────────────────────────────────────────────
class _OffDaysSummary extends StatelessWidget {
  final List<int> offDays;
  final VoidCallback onEdit;
  const _OffDaysSummary(
      {required this.offDays, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final names = offDays.map((d) => dayNames[d]).join(', ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Off days: $names',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          GestureDetector(
            onTap: onEdit,
            child: const Text('Edit',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// CATEGORY ROUTINES SCREEN
// ──────────────────────────────────────────────
class _CategoryRoutinesScreen extends ConsumerWidget {
  final String category;
  final List<RoutineModel> routines;
  const _CategoryRoutinesScreen(
      {required this.category, required this.routines});

  List<RoutineModel> _filter(List<RoutineModel> all) {
    switch (category) {
      case 'normal':
        return all
            .where((r) =>
        r.contextTags.contains('weekday') ||
            (!r.contextTags.contains('holiday') &&
                !r.contextTags.contains('special') &&
                !r.contextTags.contains('weekend')))
            .toList();
      case 'holiday':
        return all
            .where((r) =>
        r.contextTags.contains('holiday') ||
            r.contextTags.contains('weekend'))
            .toList();
      case 'special':
        return all
            .where((r) =>
        r.contextTags.contains('special') ||
            r.contextTags.contains('rainy'))
            .toList();
      default:
        return all
            .where((r) => r.contextTags.contains(category))
            .toList();
    }
  }

  String get _title {
    switch (category) {
      case 'normal':  return 'Normal Day Routines';
      case 'holiday': return 'Holiday Routines';
      case 'special': return 'Special Routines';
      default:
        return '${category[0].toUpperCase()}${category.substring(1)} Routines';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveRoutines =
        ref.watch(routinesProvider).valueOrNull ?? routines;
    final filtered   = _filter(liveRoutines);
    final timeGroups = ['morning', 'afternoon', 'night'];

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New routine',
            onPressed: () => context.push('/routine-editor'),
          ),
        ],
      ),
      body: filtered.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_outlined,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('No routines in $_title yet',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text(
              'Create a routine and tag it\nwith the matching context tag.',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.push('/routine-editor'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create routine'),
            ),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: timeGroups.expand((cat) {
          final group = filtered
              .where((r) => r.timeCategory == cat)
              .toList();
          if (group.isEmpty) return <Widget>[];
          return [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                ContextTagChip(tag: cat),
                const SizedBox(width: 8),
                Text(
                  '${group.length} routine${group.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary),
                ),
              ]),
            ),
            ...group.map((r) => RoutineCard(routine: r)),
            const SizedBox(height: 10),
          ];
        }).toList(),
      ),
    );
  }
}