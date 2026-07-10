import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared onboarding selections carried across screens.
class OnboardingSession {
  const OnboardingSession({
    this.selectedCategory,
    this.createdGoalId,
    this.targetGoalId,
  });

  final String? selectedCategory;
  final String? createdGoalId;
  final String? targetGoalId;

  OnboardingSession copyWith({
    String? selectedCategory,
    String? createdGoalId,
    String? targetGoalId,
    bool clearTargetGoalId = false,
  }) {
    return OnboardingSession(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      createdGoalId: createdGoalId ?? this.createdGoalId,
      targetGoalId: clearTargetGoalId ? null : targetGoalId ?? this.targetGoalId,
    );
  }
}

class OnboardingSessionNotifier extends StateNotifier<OnboardingSession> {
  OnboardingSessionNotifier() : super(const OnboardingSession());

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setCreatedGoalId(String goalId) {
    state = state.copyWith(createdGoalId: goalId);
  }

  void setTargetGoalId(String goalId) {
    state = state.copyWith(targetGoalId: goalId);
  }

  void clearTargetGoalId() {
    state = state.copyWith(clearTargetGoalId: true);
  }
}

final onboardingSessionProvider =
    StateNotifierProvider<OnboardingSessionNotifier, OnboardingSession>(
  (ref) => OnboardingSessionNotifier(),
);
