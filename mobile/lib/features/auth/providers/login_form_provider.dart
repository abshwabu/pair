import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/features/auth/services/auth_service.dart';

class LoginFormState {
  const LoginFormState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.error,
    this.emailError,
    this.passwordError,
  });

  final String email;
  final String password;
  final bool isLoading;
  final String? error;
  final String? emailError;
  final String? passwordError;

  LoginFormState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    String? error,
    String? emailError,
    String? passwordError,
    bool clearErrors = false,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      error: clearErrors ? null : error ?? this.error,
      emailError: clearErrors ? null : emailError ?? this.emailError,
      passwordError: clearErrors ? null : passwordError ?? this.passwordError,
    );
  }
}

class LoginFormNotifier extends StateNotifier<LoginFormState> {
  LoginFormNotifier(this._authService) : super(const LoginFormState());

  final AuthService _authService;

  void setEmail(String value) =>
      state = state.copyWith(email: value, clearErrors: true);

  void setPassword(String value) =>
      state = state.copyWith(password: value, clearErrors: true);

  String? _validate() {
    String? emailError;
    String? passwordError;

    if (state.email.trim().isEmpty) {
      emailError = 'Email is required.';
    } else if (!state.email.contains('@')) {
      emailError = 'Enter a valid email address.';
    }

    if (state.password.isEmpty) {
      passwordError = 'Password is required.';
    }

    if (emailError != null || passwordError != null) {
      state = state.copyWith(
        emailError: emailError,
        passwordError: passwordError,
        clearErrors: false,
      );
      return null;
    }
    return 'ok';
  }

  Future<String?> submit() async {
    if (_validate() == null) return null;

    state = state.copyWith(isLoading: true, clearErrors: true);

    try {
      final response = await _authService.login(
        email: state.email.trim(),
        password: state.password,
      );
      await _authService.persistToken(response.token);
      final route = await _authService.resolvePostAuthRoute();
      state = state.copyWith(isLoading: false);
      return route;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to sign in. Please try again.',
      );
      return null;
    }
  }
}

final loginFormProvider =
    StateNotifierProvider<LoginFormNotifier, LoginFormState>((ref) {
  return LoginFormNotifier(ref.watch(authServiceProvider));
});
