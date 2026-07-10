import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/features/onboarding/data/onboarding_options.dart';
import 'package:pair/features/onboarding/services/matching_prefs_storage.dart';

class MatchingPrefsFormState {
  const MatchingPrefsFormState({
    this.timezoneToleranceHours = 3,
    this.language = 'en',
    this.isLoading = false,
    this.isInitializing = true,
    this.error,
  });

  final int timezoneToleranceHours;
  final String language;
  final bool isLoading;
  final bool isInitializing;
  final String? error;

  MatchingPrefsFormState copyWith({
    int? timezoneToleranceHours,
    String? language,
    bool? isLoading,
    bool? isInitializing,
    String? error,
    bool clearErrors = false,
  }) {
    return MatchingPrefsFormState(
      timezoneToleranceHours:
          timezoneToleranceHours ?? this.timezoneToleranceHours,
      language: language ?? this.language,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: clearErrors ? null : error ?? this.error,
    );
  }
}

class MatchingPrefsFormNotifier extends StateNotifier<MatchingPrefsFormState> {
  MatchingPrefsFormNotifier(this._storage)
      : super(const MatchingPrefsFormState()) {
    _initialize();
  }

  final MatchingPrefsStorage _storage;

  Future<void> _initialize() async {
    final saved = await _storage.load();
    final deviceLanguage = ui.PlatformDispatcher.instance.locale.languageCode;
    final language = LanguageOptions.labels.containsKey(deviceLanguage)
        ? deviceLanguage
        : 'en';

    state = state.copyWith(
      timezoneToleranceHours: saved?.timezoneToleranceHours ?? 3,
      language: saved?.language ?? language,
      isInitializing: false,
    );
  }

  void setTimezoneTolerance(int hours) {
    state = state.copyWith(timezoneToleranceHours: hours, clearErrors: true);
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language, clearErrors: true);
  }

  void clearError() => state = state.copyWith(clearErrors: true);

  Future<bool> submit() async {
    state = state.copyWith(isLoading: true, clearErrors: true);

    try {
      await _storage.save(
        MatchingPrefs(
          timezoneToleranceHours: state.timezoneToleranceHours,
          language: state.language,
        ),
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to save preferences. Please try again.',
      );
      return false;
    }
  }
}

final matchingPrefsFormProvider =
    StateNotifierProvider<MatchingPrefsFormNotifier, MatchingPrefsFormState>(
  (ref) {
    return MatchingPrefsFormNotifier(ref.watch(matchingPrefsStorageProvider));
  },
);
