import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/error_banner.dart';
import 'package:pair/features/chat/providers/chat_provider.dart';
import 'package:pair/features/chat/widgets/message_bubble.dart';
import 'package:pair/features/matching/providers/finding_match_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.podId});

  final String podId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 80) {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;
      ref.read(chatProvider((podId: widget.podId, userId: user.id)).notifier)
          .loadMore();
    }
  }

  ChatArgs? get _chatArgs {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return null;
    return (podId: widget.podId, userId: user.id);
  }

  Future<void> _sendMessage() async {
    final args = _chatArgs;
    if (args == null) return;

    final text = _textController.text;
    if (text.trim().isEmpty) return;

    _textController.clear();
    final error = await ref.read(chatProvider(args).notifier).sendMessage(text);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
    _scrollToBottom();
  }

  Future<void> _pickAttachment() async {
    final args = _chatArgs;
    if (args == null) return;

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;

    final error =
        await ref.read(chatProvider(args).notifier).sendAttachment(image.path);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = _chatArgs;
    final theme = Theme.of(context);

    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final chatState = ref.watch(chatProvider(args));
    final notifier = ref.read(chatProvider(args).notifier);
    final podAsync = ref.watch(podDetailProvider(widget.podId));
    final partnerName = podAsync.asData?.value
        .activePartnerFor(args.userId)
        ?.user
        .name;

    return Scaffold(
      appBar: AppBar(
        title: Text(partnerName != null ? 'Chat with $partnerName' : 'Chat'),
      ),
      body: Column(
        children: [
          if (chatState.error != null && chatState.hasLoaded)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: ErrorBanner(
                message: chatState.error!,
                onDismiss: notifier.clearError,
              ),
            ),
          Expanded(
            child: chatState.isLoading && !chatState.hasLoaded
                ? const Center(child: CircularProgressIndicator())
                : chatState.messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'No messages yet. Say hello!',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        itemCount: chatState.messages.length +
                            (chatState.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (chatState.isLoadingMore &&
                              index == chatState.messages.length) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }

                          final reversedIndex =
                              chatState.messages.length - 1 - index;
                          final message = chatState.messages[reversedIndex];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: MessageBubble(
                              message: message,
                              isMine: message.isFrom(args.userId),
                            ),
                          );
                        },
                      ),
          ),
          if (chatState.partnerIsTyping)
            _TypingIndicator(name: chatState.partnerTypingName),
          _MessageComposer(
            controller: _textController,
            isSending: chatState.isSending,
            isUploading: chatState.isUploadingAttachment,
            onSend: _sendMessage,
            onAttachment: _pickAttachment,
            onChanged: (_) => notifier.onUserTyping(),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = name != null ? '$name is typing…' : 'Partner is typing…';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.isUploading,
    required this.onSend,
    required this.onAttachment,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool isUploading;
  final VoidCallback onSend;
  final VoidCallback onAttachment;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBusy = isSending || isUploading;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.colorScheme.outline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: isBusy ? null : onAttachment,
              icon: isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_outlined),
              tooltip: 'Send image',
            ),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Message…',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            IconButton(
              onPressed: isBusy ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.send, color: theme.colorScheme.primary),
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }
}
