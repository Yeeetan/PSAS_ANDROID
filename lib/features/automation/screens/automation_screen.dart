import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/services/firebase_service.dart';
import '../models/routine_model.dart';
import '../widgets/routine_card.dart';
import '../widgets/context_tag_chip.dart';

class AutomationScreen extends ConsumerWidget {
  const AutomationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI brain'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New routine',
            onPressed: () => context.push('/routine-editor'),
          ),
        ],
      ),
      body: routinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (routines) => routines.isEmpty
            ? _emptyState(context)
            : _categorisedList(routines),
      ),
    );
  }

  Widget _categorisedList(List<RoutineModel> routines) {
    final categories = ['morning', 'afternoon', 'night'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: categories.expand((cat) {
        final group = routines.where((r) => r.timeCategory == cat).toList();
        if (group.isEmpty) return <Widget>[];
        return [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                ContextTagChip(tag: cat),
                const SizedBox(width: 8),
                Text('${group.length} routine${group.length > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          ...group.map((r) => RoutineCard(routine: r)),
          const SizedBox(height: 10),
        ];
      }).toList(),
    );
  }

  Widget _emptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.auto_awesome_outlined, size: 64, color: AppColors.textHint),
        const SizedBox(height: 16),
        const Text('No routines yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        const Text('Create a routine or let the AI discover\nyour patterns automatically.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => context.push('/routine-editor'),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Create routine'),
        ),
      ],
    ),
  );
}