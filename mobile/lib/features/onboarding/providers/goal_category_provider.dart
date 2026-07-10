import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/features/onboarding/providers/onboarding_session_provider.dart';

class GoalCategoryOption {
  const GoalCategoryOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

const goalCategories = [
  GoalCategoryOption(id: 'read', label: 'Read', icon: Icons.menu_book_outlined),
  GoalCategoryOption(
    id: 'watch',
    label: 'Watch',
    icon: Icons.play_circle_outline,
  ),
  GoalCategoryOption(
    id: 'fitness',
    label: 'Fitness',
    icon: Icons.fitness_center_outlined,
  ),
  GoalCategoryOption(id: 'habit', label: 'Habit', icon: Icons.repeat_outlined),
  GoalCategoryOption(id: 'custom', label: 'Custom', icon: Icons.edit_outlined),
];

class GoalCategoryState {
  const GoalCategoryState({this.selectedCategory});

  final String? selectedCategory;
}

class GoalCategoryNotifier extends StateNotifier<GoalCategoryState> {
  GoalCategoryNotifier(this._sessionNotifier) : super(const GoalCategoryState());

  final OnboardingSessionNotifier _sessionNotifier;

  void selectCategory(String category) {
    _sessionNotifier.setCategory(category);
    state = GoalCategoryState(selectedCategory: category);
  }
}

final goalCategoryProvider =
    StateNotifierProvider<GoalCategoryNotifier, GoalCategoryState>((ref) {
  return GoalCategoryNotifier(ref.read(onboardingSessionProvider.notifier));
});
