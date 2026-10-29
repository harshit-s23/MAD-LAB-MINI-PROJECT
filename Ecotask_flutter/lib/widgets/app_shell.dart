import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'eco_background.dart';

/// Authenticated layout (Layout.jsx): header with logo + account menu and a
/// bottom navigation bar instead of the desktop sidebar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _tabs = [
    ('/dashboard', 'Dashboard', '🌿'),
    ('/tasks', 'Tasks', '✅'),
  ];

  int get _index {
    final i = _tabs.indexWhere((t) => location.startsWith(t.$1));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ecoBg,
      body: EcoBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _TopBar(),
              Expanded(child: child),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.forest100))),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => context.go(_tabs[i].$1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final t in _tabs)
              NavigationDestination(
                icon: Text(t.$3, style: const TextStyle(fontSize: 20)),
                label: t.$2,
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      decoration: const BoxDecoration(
        color: AppColors.glassFill,
        border: Border(bottom: BorderSide(color: AppColors.forest100)),
      ),
      child: Row(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text('EcoTask',
              style: AppText.displayStyle(18, color: AppColors.forest900)),
          const Spacer(),
          IconButton(
            key: const Key('account-menu'),
            tooltip: 'Account',
            icon: const Icon(Icons.menu_rounded, color: AppColors.forest800),
            onPressed: () => _showAccountSheet(context),
          ),
        ],
      ),
    );
  }

  void _showAccountSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        final user = context.read<AuthProvider>().user;
        final level = user?.levelData;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.forest50,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          color: AppColors.forest200, shape: BoxShape.circle),
                      child: Text(level?.emoji ?? '🌱',
                          style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.bodyStyle(14,
                                  weight: FontWeight.w600,
                                  color: AppColors.forest900)),
                          Text(level?.name ?? 'Seedling', style: AppText.small),
                        ],
                      ),
                    ),
                    Text('🔥 ${user?.streak ?? 0} day streak',
                        style: AppText.bodyStyle(12,
                            weight: FontWeight.w500,
                            color: AppColors.earth600)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('logout'),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.read<AuthProvider>().logout();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.red500,
                  alignment: Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        );
      },
    );
  }
}
