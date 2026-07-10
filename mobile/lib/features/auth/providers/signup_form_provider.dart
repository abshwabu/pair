import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/features/auth/services/auth_service.dart';

class SignupFormState {
  const SignupFormState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.isLoading = false,
    this.error,
    this.nameError,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
  });

  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final bool isLoading;
  final String? error;
  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;

  SignupFormState copyWith({
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    bool? isLoading,
    String? error,
    String? nameError,
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,
    bool clearErrors = false,
  }) {
    return SignupFormState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isLoading: isLoading ?? this.isLoading,
      error: clearErrors ? null : error ?? this.error,
      nameError: clearErrors ? null : nameError ?? this.nameError,
      emailError: clearErrors ? null : emailError ?? this.emailError,
      passwordError: clearErrors ? null : passwordError ?? this.passwordError,
      confirmPasswordError: clearErrors
          ? null
          : confirmPasswordError ?? this.confirmPasswordError,
    );
  }
}

class SignupFormNotifier extends StateNotifier<SignupFormState> {
  SignupFormNotifier(this._authService) : super(const SignupFormState());

  final AuthService _authService;

  void setName(String value) =>
      state = state.copyWith(name: value, clearErrors: true);

  void setEmail(String value) =>
      state = state.copyWith(email: value, clearErrors: true);

  void setPassword(String value) =>
      state = state.copyWith(password: value, clearErrors: true);

  void setConfirmPassword(String value) =>
      state = state.copyWith(confirmPassword: value, clearErrors: true);

  bool _validate() {
    String? nameError;
    String? emailError;
    String? passwordError;
    String? confirmPasswordError;

    if (state.name.trim().isEmpty) {
      nameError = 'Name is required.';
    }

    if (state.email.trim().isEmpty) {
      emailError = 'Email is required.';
    } else if (!state.email.contains('@')) {
      emailError = 'Enter a valid email address.';
    }

    if (state.password.length < 8) {
      passwordError = 'Password must be at least 8 characters.';
    }

    if (state.confirmPassword != state.password) {
      confirmPasswordError = 'Passwords do not match.';
    }

    if (nameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmPasswordError != null) {
      state = state.copyWith(
        nameError: nameError,
        emailError: emailError,
        passwordError: passwordError,
        confirmPasswordError: confirmPasswordError,
        clearErrors: false,
      );
      return false;
    }
    return true;
  }

  Future<String?> submit() async {
    if (!_validate()) return null;

    state = state.copyWith(isLoading: true, clearErrors: true);

    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      final response = await _authService.register(
        name: state.name.trim(),
        email: state.email.trim(),
        password: state.password,
        timezone: timezone,
      );
      await _authService.persistToken(response.token);
      state = state.copyWith(isLoading: false);
      return AppRoutes.profileSetup;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to create account. Please try again.',
      );
      return null;
    }
  }
}

final signupFormProvider =
    StateNotifierProvider<SignupFormNotifier, SignupFormState>((ref) {
  return SignupFormNotifier(ref.watch(authServiceProvider));
});
