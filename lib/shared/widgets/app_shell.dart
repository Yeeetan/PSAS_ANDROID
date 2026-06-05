import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/models/device_model.dart';

class _Tab {
  final String path;
  final IconData icon;
  final IconData iconActive;
  final String label;
  const _Tab(this.path, this.icon, this.iconActive, this.label);
}

const _tabs = [
  _Tab('/home',       Icons.map_outlined,          Icons.map,           'Home'),
  _Tab('/automation', Icons.auto_awesome_outlined,  Icons.auto_awesome,  'AI brain'),
  _Tab('/inbox',      Icons.inbox_outlined,         Icons.inbox,         'Inbox'),
  _Tab('/settings',   Icons.settings_outlined,      Icons.settings,      'Settings'),
];

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final i = _tabs.indexWhere((t) => t.path == loc);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx      = _currentIndex(context);
    final devices  = ref.watch(devicesProvider).valueOrNull ?? [];
    final inboxCount = ref.watch(aiInboxProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      body: child,

      // "Leave home" FAB — turns everything off
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _confirmTurnAllOff(context, devices),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.exit_to_app_rounded, size: 18),
        label: const Text('Leave House', style: TextStyle(fontSize: 13)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 4,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Left two tabs
              ..._tabs.sublist(0, 2).asMap().entries.map(
                    (e) => _navItem(context, e.key, e.value, idx, inboxCount),
              ),
              // Centre gap for the FAB
              const SizedBox(width: 72),
              // Right two tabs
              ..._tabs.sublist(2).asMap().entries.map(
                    (e) => _navItem(context, e.key + 2, e.value, idx, inboxCount),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int i, _Tab tab, int currentIdx, int inboxCount) {
    final selected = i == currentIdx;
    return Expanded(
      child: InkWell(
        onTap: () => context.go(tab.path),
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? tab.iconActive : tab.icon,
                  size: 22,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                // Inbox badge
                if (tab.path == '/inbox' && inboxCount > 0)
                  Positioned(
                    top: -4, right: -6,
                    child: Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '$inboxCount',
                          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmTurnAllOff(BuildContext context, List<DeviceModel> devices) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave home?'),
        content: const Text('This will turn off all devices immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Turn all off'),
          ),
        ],
      ),
    );
    if (ok == true) await FirebaseService.turnAllOff(devices);
  }
}