import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/core/network/realtime_client.dart';
import 'package:pair/features/chat/models/message_model.dart';
import 'package:pair/features/chat/services/chat_service.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSending = false,
    this.isUploadingAttachment = false,
    this.partnerIsTyping = false,
    this.partnerTypingName,
    this.nextCursor,
    this.hasMore = false,
    this.error,
    this.hasLoaded = false,
  });

  final List<MessageModel> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSending;
  final bool isUploadingAttachment;
  final bool partnerIsTyping;
  final String? partnerTypingName;
  final String? nextCursor;
  final bool hasMore;
  final String? error;
  final bool hasLoaded;

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSending,
    bool? isUploadingAttachment,
    bool? partnerIsTyping,
    String? partnerTypingName,
    String? nextCursor,
    bool? hasMore,
    String? error,
    bool? hasLoaded,
    bool clearPartnerTyping = false,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
      isUploadingAttachment:
          isUploadingAttachment ?? this.isUploadingAttachment,
      partnerIsTyping: clearPartnerTyping
          ? false
          : partnerIsTyping ?? this.partnerIsTyping,
      partnerTypingName: clearPartnerTyping
          ? null
          : partnerTypingName ?? this.partnerTypingName,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : error ?? this.error,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

typedef ChatArgs = ({String podId, String userId});

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._ref, this._args) : super(const ChatState()) {
    _init();
  }

  final Ref _ref;
  final ChatArgs _args;

  String get _podId => _args.podId;
  String get _currentUserId => _args.userId;

  StreamSubscription<PodRealtimeEvent>? _realtimeSub;
  Timer? _partnerTypingHideTimer;
  DateTime? _lastTypingSentAt;

  Future<void> _init() async {
    await loadInitial();
    final stream = await _ref.read(realtimeClientProvider).subscribeToPod(_podId);
    _realtimeSub = stream.listen(_handleRealtimeEvent);
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final page = await _ref.read(chatServiceProvider).listMessages(
            podId: _podId,
          );
      state = state.copyWith(
        messages: page.messages,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoading: false,
        hasLoaded: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load messages.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.nextCursor == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final page = await _ref.read(chatServiceProvider).listMessages(
            podId: _podId,
            cursor: state.nextCursor,
          );
      state = state.copyWith(
        messages: [...page.messages, ...state.messages],
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Unable to load older messages.',
      );
    }
  }

  Future<String?> sendMessage(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;

    state = state.copyWith(isSending: true, clearError: true);

    try {
      final message = await _ref.read(chatServiceProvider).sendMessage(
            podId: _podId,
            body: trimmed,
          );
      _appendMessage(message);
      state = state.copyWith(isSending: false);
      return null;
    } on ApiException catch (e) {
      state = state.copyWith(isSending: false, error: e.message);
      return e.message;
    } catch (_) {
      state = state.copyWith(
        isSending: false,
        error: 'Unable to send message.',
      );
      return 'Unable to send message.';
    }
  }

  Future<String?> sendAttachment(String filePath) async {
    state = state.copyWith(isUploadingAttachment: true, clearError: true);

    try {
      final url = await _ref.read(chatServiceProvider).uploadAttachment(
            podId: _podId,
            filePath: filePath,
          );
      final message = await _ref.read(chatServiceProvider).sendMessage(
            podId: _podId,
            attachmentUrl: url,
          );
      _appendMessage(message);
      state = state.copyWith(isUploadingAttachment: false);
      return null;
    } on ApiException catch (e) {
      state = state.copyWith(isUploadingAttachment: false, error: e.message);
      return e.message;
    } catch (_) {
      state = state.copyWith(
        isUploadingAttachment: false,
        error: 'Unable to upload attachment.',
      );
      return 'Unable to upload attachment.';
    }
  }

  void onUserTyping() {
    final now = DateTime.now();
    final lastSent = _lastTypingSentAt;
    if (lastSent == null ||
        now.difference(lastSent) >= const Duration(seconds: 3)) {
      _lastTypingSentAt = now;
      unawaited(_ref.read(chatServiceProvider).sendTyping(_podId));
    }
  }

  void _handleRealtimeEvent(PodRealtimeEvent event) {
    if (event.podId != _podId) return;

    switch (event.eventName) {
      case 'MessageSent':
        final incoming = MessageModel.fromBroadcast(
          podId: _podId,
          json: event.data,
        );
        if (incoming.isFrom(_currentUserId)) {
          final alreadyHave = state.messages.any(incoming.isDuplicateOf);
          if (alreadyHave) return;
        }
        _appendMessage(incoming);
      case 'UserTyping':
        final user = event.data['user'] as Map<String, dynamic>?;
        final userId = user?['id'] as String?;
        if (userId == null || userId == _currentUserId) return;
        state = state.copyWith(
          partnerIsTyping: true,
          partnerTypingName: user?['name'] as String?,
        );
        _partnerTypingHideTimer?.cancel();
        _partnerTypingHideTimer = Timer(const Duration(seconds: 4), () {
          state = state.copyWith(clearPartnerTyping: true);
        });
    }
  }

  void _appendMessage(MessageModel message) {
    if (state.messages.any(message.isDuplicateOf)) return;
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _partnerTypingHideTimer?.cancel();
    unawaited(
      _ref.read(realtimeClientProvider).unsubscribeFromPod(_podId),
    );
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider.autoDispose
    .family<ChatNotifier, ChatState, ChatArgs>((ref, args) {
  return ChatNotifier(ref, args);
});
