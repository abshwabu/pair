import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/features/checkins/models/check_in_model.dart';
import 'package:pair/features/checkins/models/streak_model.dart';
import 'package:pair/features/checkins/services/check_in_service.dart';

class StreakState {
  const StreakState({
    this.streak,
    this.isLoading = false,
    this.isCheckingIn = false,
    this.isNudging = false,
    this.checkInPromptDismissed = false,
    this.error,
    this.hasLoaded = false,
  });

  final StreakModel? streak;
  final bool isLoading;
  final bool isCheckingIn;
  final bool isNudging;
  final bool checkInPromptDismissed;
  final String? error;
  final bool hasLoaded;

  bool get showCheckInPrompt =>
      streak != null && !streak!.checkedInToday && !checkInPromptDismissed;

  bool get showRecoveryPrompt => streak?.isBroken ?? false;

  StreakState copyWith({
    StreakModel? streak,
    bool? isLoading,
    bool? isCheckingIn,
    bool? isNudging,
    bool? checkInPromptDismissed,
    String? error,
    bool? hasLoaded,
    bool clearError = false,
  }) {
    return StreakState(
      streak: streak ?? this.streak,
      isLoading: isLoading ?? this.isLoading,
      isCheckingIn: isCheckingIn ?? this.isCheckingIn,
      isNudging: isNudging ?? this.isNudging,
      checkInPromptDismissed:
          checkInPromptDismissed ?? this.checkInPromptDismissed,
      error: clearError ? null : error ?? this.error,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class StreakNotifier extends StateNotifier<StreakState> {
  StreakNotifier(this._ref, this._podId) : super(const StreakState()) {
    load();
  }

  final Ref _ref;
  final String _podId;

  Future<void> load() async {
    if (!state.hasLoaded) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final streak = await _ref.read(checkInServiceProvider).getStreak(_podId);
      state = state.copyWith(
        streak: streak,
        isLoading: false,
        hasLoaded: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load streak.',
      );
    }
  }

  void applyStreak(StreakModel streak) {
    state = state.copyWith(streak: streak, clearError: true);
  }

  void dismissCheckInPrompt() {
    state = state.copyWith(checkInPromptDismissed: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<String?> checkIn({String? note}) async {
    state = state.copyWith(isCheckingIn: true, clearError: true);

    try {
      final result = await _ref.read(checkInServiceProvider).createCheckIn(
            podId: _podId,
            note: note,
          );
      state = state.copyWith(
        streak: result.streak,
        isCheckingIn: false,
        checkInPromptDismissed: true,
      );
      return null;
    } on ApiException catch (e) {
      state = state.copyWith(isCheckingIn: false, error: e.message);
      return e.message;
    } catch (_) {
      state = state.copyWith(
        isCheckingIn: false,
        error: 'Unable to check in.',
      );
      return 'Unable to check in.';
    }
  }

  Future<String?> nudgePartner() async {
    state = state.copyWith(isNudging: true, clearError: true);

    try {
      await _ref.read(checkInServiceProvider).nudgePartner(_podId);
      state = state.copyWith(isNudging: false);
      return null;
    } on ApiException catch (e) {
      state = state.copyWith(isNudging: false, error: e.message);
      return e.message;
    } catch (_) {
      state = state.copyWith(
        isNudging: false,
        error: 'Unable to nudge your partner.',
      );
      return 'Unable to nudge your partner.';
    }
  }
}

final streakProvider = StateNotifierProvider.autoDispose
    .family<StreakNotifier, StreakState, String>((ref, podId) {
  return StreakNotifier(ref, podId);
});

class StreakDetailData {
  const StreakDetailData({
    required this.streak,
    required this.dayGroups,
  });

  final StreakModel streak;
  final List<CheckInDayGroup> dayGroups;
}

final streakDetailProvider =
    FutureProvider.autoDispose.family<StreakDetailData, String>((ref, podId) async {
  final service = ref.watch(checkInServiceProvider);
  final streak = await service.getStreak(podId);
  final checkIns = await service.listCheckIns(podId);

  return StreakDetailData(
    streak: streak,
    dayGroups: CheckInDayGroup.groupByDate(checkIns),
  );
});
