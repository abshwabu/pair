import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/features/onboarding/services/goal_service.dart';

class GoalListState {
  const GoalListState({
    this.goals = const [],
    this.isLoading = false,
    this.error,
    this.hasLoaded = false,
  });

  final List<GoalModel> goals;
  final bool isLoading;
  final String? error;
  final bool hasLoaded;

  GoalListState copyWith({
    List<GoalModel>? goals,
    bool? isLoading,
    String? error,
    bool? hasLoaded,
    bool clearError = false,
  }) {
    return GoalListState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class GoalListNotifier extends StateNotifier<GoalListState> {
  GoalListNotifier(this._ref, this._category) : super(const GoalListState()) {
    load();
  }

  final Ref _ref;
  final String _category;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final goals = await _ref
          .read(goalServiceProvider)
          .listGoals(category: _category);
      state = state.copyWith(
        goals: goals,
        isLoading: false,
        hasLoaded: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load goals.',
      );
    }
  }
}

final goalListProvider = StateNotifierProvider.autoDispose
    .family<GoalListNotifier, GoalListState, String>((ref, category) {
  return GoalListNotifier(ref, category);
});
