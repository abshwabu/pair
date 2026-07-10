import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared onboarding selections carried across screens.
class OnboardingSession {
  const OnboardingSession({
    this.selectedCategory,
    this.createdGoalId,
  });

  final String? selectedCategory;
  final String? createdGoalId;

  OnboardingSession copyWith({
    String? selectedCategory,
    String? createdGoalId,
  }) {
    return OnboardingSession(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      createdGoalId: createdGoalId ?? this.createdGoalId,
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
}

final onboardingSessionProvider =
    StateNotifierProvider<OnboardingSessionNotifier, OnboardingSession>(
  (ref) => OnboardingSessionNotifier(),
);
