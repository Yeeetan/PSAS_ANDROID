import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/theme.dart';
import '../../../shared/services/firebase_service.dart';
import '../../../shared/widgets/system_health_badge.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user           = FirebaseAuth.instance.currentUser;
    final heartbeatAsync = ref.watch(hubHeartbeatProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          _section('Account'),
          _tile(
            icon: Icons.person_outline_rounded,
            title: user?.email ?? '—',
            subtitle: 'Signed in',
          ),
          const SizedBox(height: 4),
          _tile(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            color: AppColors.error,
            onTap: () async { await FirebaseService.signOut(); },
          ),
          const SizedBox(height: 20),

          _section('Hub status'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.hub_outlined,
                    size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('ESP32 hub',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                const SystemHealthBadge(),
              ]),
              const Divider(height: 20),
              heartbeatAsync.maybeWhen(
                data: (ts) {
                  if (ts == null) {
                    return const Text('No heartbeat received.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary));
                  }
                  final dt =
                  DateTime.fromMillisecondsSinceEpoch(ts * 1000);
                  return Row(children: [
                    const Text('Last seen: ',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                    Text(dt.toString().substring(0, 19),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ]);
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          _section('Automation'),
          _tile(
            icon: Icons.exit_to_app_rounded,
            title: 'Leave House settings',
            subtitle: 'Choose which devices stay ON when leaving',
            onTap: () => context.push('/leave-house-settings'),
            showArrow: true,
          ),
          const SizedBox(height: 20),

          _section('Floor plan'),
          _tile(
            icon: Icons.map_outlined,
            title: 'Manage floors & pins',
            subtitle: 'Upload plans, place device pins',
            onTap: () => context.push('/floor-setup'),
            showArrow: true,
          ),
          const SizedBox(height: 20),

          _section('About'),
          _tile(
            icon: Icons.info_outline_rounded,
            title: 'PSAS v1.0',
            subtitle: 'IoT-Based Predictive Switch Automation — FYP',
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary)),
  );

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    VoidCallback? onTap,
    bool showArrow = false,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          leading: Icon(icon,
              size: 20, color: color ?? AppColors.textSecondary),
          title: Text(title,
              style: TextStyle(
                  fontSize: 14,
                  color: color ?? AppColors.textPrimary)),
          subtitle: subtitle != null
              ? Text(subtitle,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary))
              : null,
          trailing: showArrow
              ? const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary)
              : null,
          onTap: onTap,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
}