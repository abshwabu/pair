import 'package:flutter/material.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/features/chat/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  final MessageModel message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bubbleColor = isMine
        ? (isDark ? AppColors.primaryDark : AppColors.primary)
        : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight);

    final textColor = isMine
        ? AppColors.surfaceLight
        : theme.colorScheme.onSurface;

    final secondaryTextColor = isMine
        ? AppColors.surfaceLight.withValues(alpha: 0.75)
        : theme.colorScheme.onSurfaceVariant;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xs,
                  bottom: AppSpacing.xxs,
                ),
                child: Text(
                  message.sender.name,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.md),
                  topRight: const Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(isMine ? AppRadius.md : AppRadius.sm),
                  bottomRight: Radius.circular(isMine ? AppRadius.sm : AppRadius.md),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.attachmentUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.network(
                        message.attachmentUrl!,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return SizedBox(
                            width: 200,
                            height: 150,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          width: 200,
                          height: 120,
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.borderLight,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  if (message.body != null && message.body!.isNotEmpty) ...[
                    if (message.attachmentUrl != null)
                      const SizedBox(height: AppSpacing.xs),
                    Text(
                      message.body!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xxs,
                left: AppSpacing.xs,
                right: AppSpacing.xs,
              ),
              child: Text(
                _formatTime(message.createdAt),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: secondaryTextColor,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
