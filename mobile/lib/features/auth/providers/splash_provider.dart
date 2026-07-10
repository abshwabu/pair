import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/features/auth/services/auth_service.dart';

class SplashState {
  const SplashState({
    this.isLoading = true,
    this.error,
  });

  final bool isLoading;
  final String? error;

  SplashState copyWith({bool? isLoading, String? error}) {
    return SplashState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SplashNotifier extends StateNotifier<SplashState> {
  SplashNotifier(this._authService) : super(const SplashState());

  final AuthService _authService;

  Future<String?> bootstrap() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final route = await _authService.resolveSplashRoute();
      state = state.copyWith(isLoading: false);
      return route;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
      return null;
    }
  }
}

final splashProvider = StateNotifierProvider<SplashNotifier, SplashState>((ref) {
  return SplashNotifier(ref.watch(authServiceProvider));
});
