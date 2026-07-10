import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/features/auth/services/auth_service.dart';
import 'package:pair/features/onboarding/data/onboarding_options.dart';
import 'package:pair/features/onboarding/services/profile_service.dart';

class ProfileSetupFormState {
  const ProfileSetupFormState({
    this.name = '',
    this.timezone = 'UTC',
    this.language = 'en',
    this.avatarPath,
    this.isLoading = false,
    this.isInitializing = true,
    this.error,
    this.nameError,
  });

  final String name;
  final String timezone;
  final String language;
  final String? avatarPath;
  final bool isLoading;
  final bool isInitializing;
  final String? error;
  final String? nameError;

  ProfileSetupFormState copyWith({
    String? name,
    String? timezone,
    String? language,
    String? avatarPath,
    bool? isLoading,
    bool? isInitializing,
    String? error,
    String? nameError,
    bool clearErrors = false,
    bool clearAvatar = false,
  }) {
    return ProfileSetupFormState(
      name: name ?? this.name,
      timezone: timezone ?? this.timezone,
      language: language ?? this.language,
      avatarPath: clearAvatar ? null : avatarPath ?? this.avatarPath,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: clearErrors ? null : error ?? this.error,
      nameError: clearErrors ? null : nameError ?? this.nameError,
    );
  }
}

class ProfileSetupFormNotifier extends StateNotifier<ProfileSetupFormState> {
  ProfileSetupFormNotifier(this._authService, this._profileService)
      : super(const ProfileSetupFormState()) {
    _initialize();
  }

  final AuthService _authService;
  final ProfileService _profileService;

  Future<void> _initialize() async {
    try {
      final deviceTimezone = await FlutterTimezone.getLocalTimezone();
      final user = await _authService.me();
      final timezone = TimezoneOptions.values.contains(deviceTimezone)
          ? deviceTimezone
          : (TimezoneOptions.values.contains(user.timezone ?? '')
              ? user.timezone!
              : 'UTC');

      state = state.copyWith(
        name: user.name,
        timezone: timezone,
        language: user.language ?? 'en',
        isInitializing: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isInitializing: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isInitializing: false,
        error: 'Unable to load profile.',
      );
    }
  }

  void setName(String value) =>
      state = state.copyWith(name: value, clearErrors: true);

  void setTimezone(String value) =>
      state = state.copyWith(timezone: value, clearErrors: true);

  void setLanguage(String value) =>
      state = state.copyWith(language: value, clearErrors: true);

  void setAvatarPath(String? path) =>
      state = state.copyWith(avatarPath: path, clearErrors: true);

  bool _validate() {
    if (state.name.trim().isEmpty) {
      state = state.copyWith(nameError: 'Name is required.', clearErrors: false);
      return false;
    }
    return true;
  }

  Future<bool> submit() async {
    if (!_validate()) return false;

    state = state.copyWith(isLoading: true, clearErrors: true);

    try {
      if (state.avatarPath != null) {
        await _profileService.uploadAvatar(state.avatarPath!);
      }

      await _profileService.updateProfile(
        name: state.name.trim(),
        timezone: state.timezone,
        language: state.language,
      );

      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to save profile. Please try again.',
      );
      return false;
    }
  }

  File? get avatarFile =>
      state.avatarPath != null ? File(state.avatarPath!) : null;
}

final profileSetupFormProvider =
    StateNotifierProvider<ProfileSetupFormNotifier, ProfileSetupFormState>((ref) {
  return ProfileSetupFormNotifier(
    ref.watch(authServiceProvider),
    ref.watch(profileServiceProvider),
  );
});
