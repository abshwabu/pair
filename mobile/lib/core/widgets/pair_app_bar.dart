import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App bar with a consistent back action on every screen.
class PairAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PairAppBar({
    super.key,
    required this.title,
    this.fallbackRoute,
    this.actions,
    this.showBack = true,
  });

  final String title;
  final String? fallbackRoute;
  final List<Widget>? actions;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    if (fallbackRoute != null) {
      context.go(fallbackRoute!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack =
        showBack && (context.canPop() || fallbackRoute != null);

    return AppBar(
      title: Text(title),
      automaticallyImplyLeading: false,
      leadingWidth: canGoBack ? null : 0,
      leading: canGoBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: () => _handleBack(context),
            )
          : const SizedBox.shrink(),
      actions: actions,
    );
  }
}
