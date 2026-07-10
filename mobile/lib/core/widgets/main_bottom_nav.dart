import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/features/auth/services/auth_service.dart';

/// Resolves the authenticated user's home route (pod or goal picker).
final homeRouteProvider = FutureProvider<String>((ref) {
  return ref.watch(authServiceProvider).resolvePostAuthRoute();
});

enum MainTab { home, profile }

/// Bottom navigation for the two main authenticated tabs.
class MainBottomNav extends ConsumerWidget {
  const MainBottomNav({super.key, required this.currentTab});

  final MainTab currentTab;

  Future<void> _onTabSelected(BuildContext context, WidgetRef ref, int index) async {
    if (index == 0 && currentTab == MainTab.home) return;
    if (index == 1 && currentTab == MainTab.profile) return;

    if (index == 1) {
      context.go(AppRoutes.profile);
      return;
    }

    final homeRoute = await ref.read(homeRouteProvider.future);
    if (!context.mounted) return;
    context.go(homeRoute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationBar(
      selectedIndex: currentTab == MainTab.home ? 0 : 1,
      onDestinationSelected: (index) => _onTabSelected(context, ref, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
