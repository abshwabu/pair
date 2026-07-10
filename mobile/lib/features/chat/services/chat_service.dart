import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_client.dart';
import 'package:pair/features/chat/models/message_model.dart';

class ChatService {
  ChatService(this._api);

  final ApiClient _api;

  Future<MessagesPage> listMessages({
    required String podId,
    String? cursor,
  }) async {
    final response = await _api.get<List<dynamic>>(
      '/pods/$podId/messages',
      queryParameters: cursor != null ? {'cursor': cursor} : null,
      fromJsonT: (json) => (json as List).toList(),
    );

    final messages = (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(MessageModel.fromJson)
        .toList();

    final meta = response.meta ?? {};
    return MessagesPage(
      messages: messages,
      nextCursor: meta['next_cursor'] as String?,
      hasMore: meta['has_more'] as bool? ?? false,
    );
  }

  Future<MessageModel> sendMessage({
    required String podId,
    String? body,
    String? attachmentUrl,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/pods/$podId/messages',
      data: {
        if (body != null && body.isNotEmpty) 'body': body,
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      },
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return MessageModel.fromJson(response.data!);
  }

  Future<void> sendTyping(String podId) async {
    await _api.post<Map<String, dynamic>>(
      '/pods/$podId/typing',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  Future<String> uploadAttachment({
    required String podId,
    required String filePath,
  }) async {
    final formData = FormData.fromMap({
      'attachment': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });

    final response = await _api.postMultipart<Map<String, dynamic>>(
      '/pods/$podId/messages/attachments',
      formData: formData,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );

    return response.data!['attachment_url'] as String;
  }
}

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.watch(apiClientProvider));
});
