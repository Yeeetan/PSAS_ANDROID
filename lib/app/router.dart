import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/services/firebase_service.dart';
import '../shared/widgets/app_shell.dart';
import '../features/auth/login_screen.dart';
import '../features/floor_plan/screens/home_screen.dart';
import '../features/floor_plan/screens/floor_setup_screen.dart';
import '../features/floor_plan/screens/pin_placement_screen.dart';
import '../features/automation/screens/automation_screen.dart';
import '../features/automation/screens/routine_editor_screen.dart';
import '../features/ai_inbox/screens/inbox_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/leave_house_settings.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(
        FirebaseAuth.instance.authStateChanges()),
    redirect: (context, state) {
      final isLoggedIn  = FirebaseAuth.instance.currentUser != null;
      final isLoginPage = state.matchedLocation == '/login';
      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      // Shell wraps all bottom-nav tabs in AppShell
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home',       builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/automation', builder: (_, __) => const AutomationScreen()),
          GoRoute(path: '/inbox',      builder: (_, __) => const InboxScreen()),
          GoRoute(path: '/settings',   builder: (_, __) => const SettingsScreen()),
        ],
      ),

      // Push routes (outside the shell / bottom nav)
      GoRoute(
        path: '/floor-setup',
        builder: (_, __) => const FloorSetupScreen(),
      ),
      GoRoute(
        path: '/pin-placement/:floorId',
        builder: (_, state) =>
            PinPlacementScreen(floorId: state.pathParameters['floorId']!),
      ),
      GoRoute(
        path: '/routine-editor',
        builder: (_, state) =>
            RoutineEditorScreen(routineId: state.uri.queryParameters['id']),
      ),
      GoRoute(
        path: '/leave-house-settings',
        builder: (_, __) => const LeaveHouseSettingsScreen(),
      ),
    ],
  );
});