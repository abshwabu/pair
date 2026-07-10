import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/storage/token_storage.dart';

/// Notifies [GoRouter] when auth state changes so redirects re-run.
class RouterRefreshNotifier extends ChangeNotifier {
  void notifyAuthChanged() => notifyListeners();
}

final routerRefreshProvider = Provider<RouterRefreshNotifier>(
  (ref) => RouterRefreshNotifier(),
);

final authTokenProvider = FutureProvider<String?>((ref) async {
  return ref.watch(tokenStorageProvider).readToken();
});

void notifyAuthChanged(WidgetRef ref) {
  ref.invalidate(authTokenProvider);
  ref.read(routerRefreshProvider).notifyAuthChanged();
}
