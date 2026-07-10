import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/features/matching/models/partner_match_request_model.dart';
import 'package:pair/features/matching/services/matching_service.dart';
import 'package:pair/features/onboarding/providers/onboarding_session_provider.dart';
import 'package:pair/features/onboarding/services/matching_prefs_storage.dart';
import 'package:pair/features/onboarding/services/profile_service.dart';

class PartnerMatchPendingState {
  const PartnerMatchPendingState({
    this.isSending = true,
    this.isPolling = false,
    this.isCancelling = false,
    this.request,
    this.error,
  });

  final bool isSending;
  final bool isPolling;
  final bool isCancelling;
  final PartnerMatchRequestModel? request;
  final String? error;

  bool get isWaiting => isSending || isPolling;

  PartnerMatchPendingState copyWith({
    bool? isSending,
    bool? isPolling,
    bool? isCancelling,
    PartnerMatchRequestModel? request,
    String? error,
    bool clearError = false,
  }) {
    return PartnerMatchPendingState(
      isSending: isSending ?? this.isSending,
      isPolling: isPolling ?? this.isPolling,
      isCancelling: isCancelling ?? this.isCancelling,
      request: request ?? this.request,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class PartnerMatchPendingNotifier extends StateNotifier<PartnerMatchPendingState> {
  PartnerMatchPendingNotifier(this._ref) : super(const PartnerMatchPendingState());

  final Ref _ref;
  Timer? _pollTimer;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    final session = _ref.read(onboardingSessionProvider);
    final goalId = session.createdGoalId;
    final targetGoalId = session.targetGoalId;

    if (goalId == null || targetGoalId == null) {
      state = state.copyWith(
        isSending: false,
        error: 'Missing goal information for this match request.',
      );
      return;
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

      if (request.isAccepted && request.podId != null) {
        state = state.copyWith(isSending: false, request: request);
        return;
      }

      state = state.copyWith(
        isSending: false,
        isPolling: true,
        request: request,
      );
      _beginPolling(request.id);
    } on ApiException catch (e) {
      state = state.copyWith(isSending: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isSending: false,
        error: 'Unable to send match request. Please try again.',
      );
    }
  }

  void _beginPolling(String requestId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _poll(requestId);
    });
    _poll(requestId);
  }

  Future<void> _poll(String requestId) async {
    if (!state.isPolling) return;

    try {
      final request =
          await _ref.read(matchingServiceProvider).getPartnerRequest(requestId);

      if (request.isAccepted || request.isDeclined || request.isCancelled) {
        _pollTimer?.cancel();
        state = state.copyWith(isPolling: false, request: request);
      }
    } on ApiException catch (e) {
      _pollTimer?.cancel();
      state = state.copyWith(isPolling: false, error: e.message);
    } catch (_) {
      _pollTimer?.cancel();
      state = state.copyWith(
        isPolling: false,
        error: 'Lost connection while waiting for a response.',
      );
    }
  }

  Future<bool> cancel() async {
    _pollTimer?.cancel();

    final requestId = state.request?.id;
    if (requestId == null) {
      state = state.copyWith(isSending: false, isPolling: false, isCancelling: false);
      return true;
    }

    state = state.copyWith(isCancelling: true, clearError: true);

    try {
      await _ref.read(matchingServiceProvider).cancelPartnerRequest(requestId);
      state = state.copyWith(isCancelling: false, isPolling: false);
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

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
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
