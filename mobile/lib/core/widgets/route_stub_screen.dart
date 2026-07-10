import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/pair_app_bar.dart';

/// Placeholder screen shown until feature screens are built out.
class RouteStubScreen extends StatelessWidget {
  const RouteStubScreen({
    super.key,
    required this.routeName,
    this.showRouteExplorer = false,
  });

  final String routeName;
  final bool showRouteExplorer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PairAppBar(
        title: routeName,
        fallbackRoute: AppRoutes.splash,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              routeName,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Route stub — screen coming soon.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (showRouteExplorer) ...[
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: _RouteExplorer(currentRoute: routeName),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RouteExplorer extends StatelessWidget {
  const _RouteExplorer({required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              'Navigate to route stubs',
              style: theme.textTheme.titleMedium,
            ),
          ),
          ...AppRoutes.allStubs
              .where((route) => route != currentRoute)
              .map(
                (route) => ListTile(
                  title: Text(route),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(route),
                ),
              ),
        ],
      ),
    );
  }
}
