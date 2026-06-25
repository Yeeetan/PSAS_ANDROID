import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../app/theme.dart';
import '../../../shared/services/firebase_service.dart';
import '../../../shared/widgets/system_health_badge.dart';
import '../widgets/floor_plan_viewer.dart';

// ──────────────────────────────────────────────
// VACATION ALERT PROVIDER
// ──────────────────────────────────────────────
final vacationAlertProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return FirebaseDatabase.instance
      .ref('alerts/$kHomeId/vacation_check')
      .onValue
      .map((e) {
    final data = e.snapshot.value;
    if (data == null) return null;
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    if (map['status'] != 'pending') return null;
    return map;
  });
});

// ──────────────────────────────────────────────
// HOME SCREEN
// ──────────────────────────────────────────────
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
      _tabController =
          TabController(length: count == 0 ? 1 : count, vsync: this);
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
    final floorsAsync       = ref.watch(floorsProvider);
    final devicesAsync      = ref.watch(devicesProvider);
    final vacationAlertAsync = ref.watch(vacationAlertProvider);
    final devices           = devicesAsync.valueOrNull ?? [];
    final vacationAlert     = vacationAlertAsync.valueOrNull;

    return floorsAsync.when(
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
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
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
              tabs: floors.map((f) => Tab(text: f.name)).toList(),
            ),
          ),
          body: Column(
            children: [
              // ── Vacation Alert Banner ──
              if (vacationAlert != null)
                _VacationAlertBanner(alert: vacationAlert),

              // ── Main Content ──
              Expanded(
                child: floors.isEmpty
                    ? _emptyState(context)
                    : TabBarView(
                  controller: _tabController,
                  children: floors
                      .map((f) =>
                      FloorPlanViewer(floor: f, devices: devices))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.map_outlined,
            size: 64, color: AppColors.textHint),
        const SizedBox(height: 16),
        const Text('No floors set up',
            style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        const Text('Upload a floor plan to get started.',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
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

// ──────────────────────────────────────────────
// VACATION ALERT BANNER
// ──────────────────────────────────────────────
class _VacationAlertBanner extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _VacationAlertBanner({required this.alert});

  Future<void> _respond(BuildContext context, String status,
      {int? remindAfterDays}) async {
    final update = <String, dynamic>{'status': status};
    if (remindAfterDays != null) {
      update['remind_after_days'] = remindAfterDays;
    }
    await FirebaseDatabase.instance
        .ref('alerts/$kHomeId/vacation_check')
        .update(update);
  }

  void _showVacationDialog(BuildContext context) {
    int selectedDays = 3;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.flight_takeoff_rounded,
                  color: AppColors.error, size: 20),
              SizedBox(width: 8),
              Text('Away from home?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert['message'] as String? ??
                    'Your switches have been OFF for a long time.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              const Text('Remind me again in:',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              // Day selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [1, 3, 5, 7].map((days) {
                  final selected = selectedDays == days;
                  return GestureDetector(
                    onTap: () => setDs(() => selectedDays = days),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFFF1EFE8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$days',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              days == 1 ? 'day' : 'days',
                              style: TextStyle(
                                fontSize: 10,
                                color: selected
                                    ? Colors.white.withOpacity(0.8)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            // Not on vacation
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _respond(context, 'not_vacation');
              },
              child: const Text("I'm back home"),
            ),
            // Yes, on vacation — set reminder
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await _respond(context, 'on_vacation',
                    remindAfterDays: selectedDays);
              },
              icon: const Icon(Icons.beach_access_rounded, size: 16),
              label: Text('Away · remind in $selectedDays day${selectedDays > 1 ? 's' : ''}'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoursInactive = alert['hours_inactive'] as int? ?? 0;

    return GestureDetector(
      onTap: () => _showVacationDialog(context),
      child: Container(
        width: double.infinity,
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.error.withOpacity(0.95),
        child: Row(
          children: [
            const Icon(Icons.flight_takeoff_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Are you on vacation?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'No switch activity for ${hoursInactive}h. Tap to respond.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Quick dismiss
            GestureDetector(
              onTap: () => _respond(context, 'dismissed'),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}