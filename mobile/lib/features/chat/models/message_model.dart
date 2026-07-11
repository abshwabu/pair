class MessageSender {
  const MessageSender({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? avatarUrl;

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class MessageModel {
  const MessageModel({
    required this.id,
    required this.podId,
    required this.sender,
    this.body,
    this.attachmentUrl,
    required this.createdAt,
  });

  final String id;
  final String podId;
  final MessageSender sender;
  final String? body;
  final String? attachmentUrl;
  final DateTime createdAt;

  bool isFrom(String userId) => sender.id == userId;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String? ?? _syntheticId(json),
      podId: json['pod_id'] as String,
      sender: MessageSender.fromJson(json['sender'] as Map<String, dynamic>),
      body: json['body'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  factory MessageModel.fromBroadcast({
    required String podId,
    required Map<String, dynamic> json,
  }) {
    return MessageModel(
      id: json['id'] as String? ?? _syntheticId(json),
      podId: podId,
      sender: MessageSender.fromJson(json['sender'] as Map<String, dynamic>),
      body: json['body'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static String _syntheticId(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    final createdAt = json['created_at'] as String? ?? '';
    final body = json['body'] as String? ?? '';
    return 'live-$createdAt-${sender?['id']}-$body';
  }

  bool isDuplicateOf(MessageModel other) {
    if (id == other.id) return true;
    return sender.id == other.sender.id &&
        body == other.body &&
        attachmentUrl == other.attachmentUrl &&
        createdAt.difference(other.createdAt).abs() <
            const Duration(seconds: 5);
  }
}

class MessagesPage {
  const MessagesPage({
    required this.messages,
    this.nextCursor,
    required this.hasMore,
  });

  final List<MessageModel> messages;
  final String? nextCursor;
  final bool hasMore;
}
