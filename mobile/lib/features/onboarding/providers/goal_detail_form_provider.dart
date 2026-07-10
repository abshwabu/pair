import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/features/onboarding/providers/onboarding_session_provider.dart';
import 'package:pair/features/onboarding/services/goal_service.dart';

class GoalDetailFormState {
  const GoalDetailFormState({
    this.title = '',
    this.targetDescription = '',
    this.pace = 'steady',
    this.isLoading = false,
    this.error,
    this.titleError,
    this.targetDescriptionError,
  });

  final String title;
  final String targetDescription;
  final String pace;
  final bool isLoading;
  final String? error;
  final String? titleError;
  final String? targetDescriptionError;

  GoalDetailFormState copyWith({
    String? title,
    String? targetDescription,
    String? pace,
    bool? isLoading,
    String? error,
    String? titleError,
    String? targetDescriptionError,
    bool clearErrors = false,
  }) {
    return GoalDetailFormState(
      title: title ?? this.title,
      targetDescription: targetDescription ?? this.targetDescription,
      pace: pace ?? this.pace,
      isLoading: isLoading ?? this.isLoading,
      error: clearErrors ? null : error ?? this.error,
      titleError: clearErrors ? null : titleError ?? this.titleError,
      targetDescriptionError: clearErrors
          ? null
          : targetDescriptionError ?? this.targetDescriptionError,
    );
  }
}

class GoalDetailFormNotifier extends StateNotifier<GoalDetailFormState> {
  GoalDetailFormNotifier(this._goalService, this._sessionNotifier)
      : super(const GoalDetailFormState());

  final GoalService _goalService;
  final OnboardingSessionNotifier _sessionNotifier;

  void setTitle(String value) =>
      state = state.copyWith(title: value, clearErrors: true);

  void setTargetDescription(String value) =>
      state = state.copyWith(targetDescription: value, clearErrors: true);

  void setPace(String value) =>
      state = state.copyWith(pace: value, clearErrors: true);

  void clearError() => state = state.copyWith(clearErrors: true);

  bool _validate() {
    String? titleError;
    String? targetDescriptionError;

    if (state.title.trim().isEmpty) {
      titleError = 'Title is required.';
    }

    if (state.targetDescription.trim().isEmpty) {
      targetDescriptionError = 'Describe your target.';
    }

    if (titleError != null || targetDescriptionError != null) {
      state = state.copyWith(
        titleError: titleError,
        targetDescriptionError: targetDescriptionError,
        clearErrors: false,
      );
      return false;
    }
    return true;
  }

  Future<bool> submit(String? category) async {
    if (category == null) {
      state = state.copyWith(
        error: 'Select a goal category first.',
        clearErrors: false,
      );
      return false;
    }

    if (!_validate()) return false;

    state = state.copyWith(isLoading: true, clearErrors: true);

    try {
      final goal = await _goalService.createGoal(
        category: category,
        title: state.title.trim(),
        targetDescription: state.targetDescription.trim(),
        pace: state.pace,
      );
      _sessionNotifier.setCreatedGoalId(goal.id);
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to create goal. Please try again.',
      );
      return false;
    }
  }
}

final goalDetailFormProvider =
    StateNotifierProvider<GoalDetailFormNotifier, GoalDetailFormState>((ref) {
  return GoalDetailFormNotifier(
    ref.watch(goalServiceProvider),
    ref.read(onboardingSessionProvider.notifier),
  );
});

const goalPaceOptions = ['relaxed', 'steady', 'intense'];
