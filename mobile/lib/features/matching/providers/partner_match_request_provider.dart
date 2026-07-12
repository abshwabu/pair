import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/features/matching/models/partner_match_request_model.dart';
import 'package:pair/features/matching/services/matching_service.dart';
import 'package:pair/features/onboarding/providers/onboarding_session_provider.dart';
import 'package:pair/features/onboarding/services/matching_prefs_storage.dart';
import 'package:pair/features/onboarding/services/profile_service.dart';

class PartnerMatchPendingState {
  const PartnerMatchPendingState({
    this.isSending = false,
    this.isSent = false,
    this.isCancelling = false,
    this.request,
    this.error,
  });

  final bool isSending;
  final bool isSent;
  final bool isCancelling;
  final PartnerMatchRequestModel? request;
  final String? error;

  PartnerMatchPendingState copyWith({
    bool? isSending,
    bool? isSent,
    bool? isCancelling,
    PartnerMatchRequestModel? request,
    String? error,
    bool clearError = false,
  }) {
    return PartnerMatchPendingState(
      isSending: isSending ?? this.isSending,
      isSent: isSent ?? this.isSent,
      isCancelling: isCancelling ?? this.isCancelling,
      request: request ?? this.request,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class PartnerMatchPendingNotifier extends StateNotifier<PartnerMatchPendingState> {
  PartnerMatchPendingNotifier(this._ref) : super(const PartnerMatchPendingState());

  final Ref _ref;

  Future<bool> send() async {
    final session = _ref.read(onboardingSessionProvider);
    final goalId = session.createdGoalId;
    final targetGoalId = session.targetGoalId;

    if (goalId == null || targetGoalId == null) {
      state = state.copyWith(
        error: 'Missing goal information for this match request.',
      );
      return false;
    }

    if (state.isSent &&
        state.request?.recipientGoal?.id == targetGoalId &&
        state.error == null) {
      return true;
    }

    if (state.isSending) {
      return false;
    }

    if (state.isSent && state.request?.recipientGoal?.id != targetGoalId) {
      state = const PartnerMatchPendingState();
    }

    final prefs = await _ref.read(matchingPrefsStorageProvider).load();
    final timezoneToleranceHours = prefs?.timezoneToleranceHours ?? 3;
    final language = prefs?.language ?? 'en';

    state = state.copyWith(isSending: true, clearError: true);

    try {
      await _ref.read(profileServiceProvider).updateProfile(language: language);

      final request = await _ref.read(matchingServiceProvider).createPartnerRequest(
            goalId: goalId,
            targetGoalId: targetGoalId,
            timezoneToleranceHours: timezoneToleranceHours,
          );

      state = state.copyWith(
        isSending: false,
        isSent: true,
        request: request,
      );
      _ref.invalidate(outgoingPartnerMatchRequestsProvider);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSending: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSending: false,
        error: 'Unable to send match request. Please try again.',
      );
      return false;
    }
  }

  Future<bool> cancel() async {
    final requestId = state.request?.id;
    if (requestId == null) {
      return true;
    }

    state = state.copyWith(isCancelling: true, clearError: true);

    try {
      await _ref.read(matchingServiceProvider).cancelPartnerRequest(requestId);
      state = state.copyWith(isCancelling: false, isSent: false, request: null);
      _ref.invalidate(outgoingPartnerMatchRequestsProvider);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isCancelling: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isCancelling: false,
        error: 'Unable to cancel match request.',
      );
      return false;
    }
  }

  void reset() {
    state = const PartnerMatchPendingState();
  }
}

final partnerMatchPendingProvider =
    StateNotifierProvider.autoDispose<PartnerMatchPendingNotifier, PartnerMatchPendingState>(
  (ref) => PartnerMatchPendingNotifier(ref),
);

final incomingPartnerMatchRequestsProvider =
    FutureProvider.autoDispose<List<PartnerMatchRequestModel>>((ref) {
  return ref.watch(matchingServiceProvider).listPartnerRequests(
        direction: 'incoming',
        pendingOnly: true,
      );
});

final outgoingPartnerMatchRequestsProvider =
    FutureProvider.autoDispose<List<PartnerMatchRequestModel>>((ref) {
  return ref.watch(matchingServiceProvider).listPartnerRequests(
        direction: 'outgoing',
        pendingOnly: true,
      );
});
