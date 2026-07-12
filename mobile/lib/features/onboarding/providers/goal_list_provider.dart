import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/features/onboarding/services/goal_service.dart';

class GoalListState {
  const GoalListState({
    this.myGoals = const [],
    this.communityGoals = const [],
    this.isLoading = false,
    this.error,
    this.communityError,
    this.hasLoaded = false,
  });

  final List<GoalModel> myGoals;
  final List<GoalModel> communityGoals;
  final bool isLoading;
  final String? error;
  final String? communityError;
  final bool hasLoaded;

  GoalListState copyWith({
    List<GoalModel>? myGoals,
    List<GoalModel>? communityGoals,
    bool? isLoading,
    String? error,
    String? communityError,
    bool? hasLoaded,
    bool clearError = false,
    bool clearCommunityError = false,
  }) {
    return GoalListState(
      myGoals: myGoals ?? this.myGoals,
      communityGoals: communityGoals ?? this.communityGoals,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      communityError:
          clearCommunityError ? null : communityError ?? this.communityError,
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
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearCommunityError: true,
    );

    final service = _ref.read(goalServiceProvider);

    List<GoalModel> myGoals = state.myGoals;
    List<GoalModel> communityGoals = state.communityGoals;
    String? myError;
    String? communityError;

    try {
      myGoals = await service.listMyGoals(category: _category);
    } on ApiException catch (e) {
      myError = e.message;
    } catch (_) {
      myError = 'Unable to load your goals.';
    }

    try {
      communityGoals = await service.browseGoals(category: _category);
    } on ApiException catch (e) {
      communityError = e.message;
    } catch (_) {
      communityError = 'Unable to load community goals.';
    }

    state = state.copyWith(
      myGoals: myGoals,
      communityGoals: communityGoals,
      isLoading: false,
      hasLoaded: true,
      error: myError,
      communityError: communityError,
    );
  }
}

final goalListProvider = StateNotifierProvider.autoDispose
    .family<GoalListNotifier, GoalListState, String>((ref, category) {
  return GoalListNotifier(ref, category);
});
