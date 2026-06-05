import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/services/firebase_service.dart';
import '../../../shared/widgets/system_health_badge.dart';
import '../widgets/floor_plan_viewer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  int _floorCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  void _rebuildTabController(int count) {
    if (count != _floorCount) {
      _tabController?.dispose();
      _tabController = TabController(length: count == 0 ? 1 : count, vsync: this);
      _floorCount = count;
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final floorsAsync  = ref.watch(floorsProvider);
    final devicesAsync = ref.watch(devicesProvider);
    final devices      = devicesAsync.valueOrNull ?? [];

    return floorsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (floors) {
        _rebuildTabController(floors.length);

        return Scaffold(
          appBar: AppBar(
            title: const Text('PSAS'),
            actions: [
              const SystemHealthBadge(),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 20),
                tooltip: 'Floor setup',
                onPressed: () => context.push('/floor-setup'),
              ),
            ],
            bottom: floors.isEmpty
                ? null
                : TabBar(
              controller: _tabController,
              isScrollable: floors.length > 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: floors.map((f) => Tab(text: f.name)).toList(),
            ),
          ),
          body: floors.isEmpty
              ? _emptyState(context)
              : TabBarView(
            controller: _tabController,
            children: floors
                .map((f) => FloorPlanViewer(floor: f, devices: devices))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.map_outlined, size: 64, color: AppColors.textHint),
        const SizedBox(height: 16),
        const Text('No floors set up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        const Text('Upload a floor plan to get started.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => context.push('/floor-setup'),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Set up floor plan'),
        ),
      ],
    ),
  );
}