import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Intercepts the system back gesture on root/home screens so the app exits
/// instead of popping to earlier routes (e.g. onboarding).
class HomeBackScope extends StatelessWidget {
  const HomeBackScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}
