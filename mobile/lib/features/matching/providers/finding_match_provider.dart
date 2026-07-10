import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/features/auth/models/user_model.dart';
import 'package:pair/features/auth/services/auth_service.dart';
import 'package:pair/features/matching/services/matching_service.dart';
import 'package:pair/features/onboarding/providers/onboarding_session_provider.dart';
import 'package:pair/features/onboarding/services/matching_prefs_storage.dart';
import 'package:pair/features/onboarding/services/profile_service.dart';
import 'package:pair/features/pods/models/pod_model.dart';
import 'package:pair/features/pods/services/pod_service.dart';

const findingMatchStatusMessages = [
  'Searching for partners with similar goals…',
  'Checking timezone compatibility…',
  'Looking for someone on your pace…',
  'Almost there — hang tight…',
];

class FindingMatchState {
  const FindingMatchState({
    this.isStarting = true,
    this.isPolling = false,
    this.isCancelling = false,
    this.requestId,
    this.error,
    this.matchedPodId,
    this.statusMessageIndex = 0,
  });

  final bool isStarting;
  final bool isPolling;
  final bool isCancelling;
  final String? requestId;
  final String? error;
  final String? matchedPodId;
  final int statusMessageIndex;

  bool get isWaiting => isStarting || isPolling;

  FindingMatchState copyWith({
    bool? isStarting,
    bool? isPolling,
    bool? isCancelling,
    String? requestId,
    String? error,
    String? matchedPodId,
    int? statusMessageIndex,
    bool clearError = false,
    bool clearMatchedPodId = false,
  }) {
    return FindingMatchState(
      isStarting: isStarting ?? this.isStarting,
      isPolling: isPolling ?? this.isPolling,
      isCancelling: isCancelling ?? this.isCancelling,
      requestId: requestId ?? this.requestId,
      error: clearError ? null : error ?? this.error,
      matchedPodId: clearMatchedPodId ? null : matchedPodId ?? this.matchedPodId,
      statusMessageIndex: statusMessageIndex ?? this.statusMessageIndex,
    );
  }
}

class FindingMatchNotifier extends StateNotifier<FindingMatchState> {
  FindingMatchNotifier(this._ref) : super(const FindingMatchState());

  final Ref _ref;
  Timer? _pollTimer;
  Timer? _messageTimer;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    final goalId = _ref.read(onboardingSessionProvider).createdGoalId;
    final targetGoalId = _ref.read(onboardingSessionProvider).targetGoalId;
    if (goalId == null) {
      state = state.copyWith(
        isStarting: false,
        error: 'Create a goal before searching for a partner.',
      );
      return;
    }

    final prefs = await _ref.read(matchingPrefsStorageProvider).load();
    final timezoneToleranceHours = prefs?.timezoneToleranceHours ?? 3;
    final language = prefs?.language ?? 'en';

    state = state.copyWith(isStarting: true, clearError: true);

    try {
      await _ref.read(profileServiceProvider).updateProfile(language: language);

      final request = await _ref.read(matchingServiceProvider).createRequest(
            goalId: goalId,
            timezoneToleranceHours: timezoneToleranceHours,
            targetGoalId: targetGoalId,
          );

      if (request.isMatched && request.podId != null) {
        state = state.copyWith(
          isStarting: false,
          isPolling: false,
          requestId: request.id,
          matchedPodId: request.podId,
        );
        return;
      }

      state = state.copyWith(
        isStarting: false,
        isPolling: true,
        requestId: request.id,
      );
      _beginTimers(request.id);
    } on ApiException catch (e) {
      state = state.copyWith(isStarting: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isStarting: false,
        error: 'Unable to start matching. Please try again.',
      );
    }
  }

  void _beginTimers(String requestId) {
    _pollTimer?.cancel();
    _messageTimer?.cancel();

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _poll(requestId);
    });

    _messageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !state.isPolling) return;
      final next = (state.statusMessageIndex + 1) % findingMatchStatusMessages.length;
      state = state.copyWith(statusMessageIndex: next);
    });

    _poll(requestId);
  }

  Future<void> _poll(String requestId) async {
    if (!state.isPolling) return;

    try {
      final request =
          await _ref.read(matchingServiceProvider).getRequest(requestId);

      if (request.isMatched && request.podId != null) {
        _stopTimers();
        state = state.copyWith(
          isPolling: false,
          matchedPodId: request.podId,
        );
        return;
      }

      if (request.isCancelled) {
        _stopTimers();
        state = state.copyWith(
          isPolling: false,
          error: 'Matching was cancelled.',
        );
      }
    } on ApiException catch (e) {
      _stopTimers();
      state = state.copyWith(isPolling: false, error: e.message);
    } catch (_) {
      _stopTimers();
      state = state.copyWith(
        isPolling: false,
        error: 'Lost connection while searching. Please try again.',
      );
    }
  }

  Future<bool> cancel() async {
    _stopTimers();

    final requestId = state.requestId;
    if (requestId == null) {
      state = state.copyWith(
        isStarting: false,
        isPolling: false,
        isCancelling: false,
      );
      return true;
    }

    state = state.copyWith(isCancelling: true, clearError: true);

    try {
      await _ref.read(matchingServiceProvider).cancelRequest(requestId);
      state = state.copyWith(isCancelling: false, isPolling: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isCancelling: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isCancelling: false,
        error: 'Unable to cancel matching. Please try again.',
      );
      return false;
    }
  }

  void _stopTimers() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _messageTimer?.cancel();
    _messageTimer = null;
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}

final findingMatchProvider =
    StateNotifierProvider.autoDispose<FindingMatchNotifier, FindingMatchState>(
  (ref) => FindingMatchNotifier(ref),
);

final currentUserProvider = FutureProvider.autoDispose<UserModel>((ref) {
  return ref.watch(authServiceProvider).me();
});

final podDetailProvider =
    FutureProvider.autoDispose.family<PodDetailModel, String>((ref, podId) {
  return ref.watch(podServiceProvider).getPod(podId);
});
