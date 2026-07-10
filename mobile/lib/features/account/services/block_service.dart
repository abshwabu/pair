import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_client.dart';

class BlockModel {
  const BlockModel({
    required this.id,
    required this.blockedUserId,
    required this.blockedUserName,
    this.blockedUserAvatarUrl,
    required this.createdAt,
  });

  final String id;
  final String blockedUserId;
  final String blockedUserName;
  final String? blockedUserAvatarUrl;
  final DateTime createdAt;

  factory BlockModel.fromJson(Map<String, dynamic> json) {
    final user = json['blocked_user'] as Map<String, dynamic>;
    return BlockModel(
      id: json['id'] as String,
      blockedUserId: user['id'] as String,
      blockedUserName: user['name'] as String,
      blockedUserAvatarUrl: user['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class BlockService {
  BlockService(this._api);

  final ApiClient _api;

  Future<List<BlockModel>> listBlocks() async {
    final response = await _api.get<List<dynamic>>(
      '/blocks',
      fromJsonT: (json) => (json as List).toList(),
    );

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(BlockModel.fromJson)
        .toList();
  }

  Future<void> blockUser(String blockedUserId) async {
    await _api.post<Map<String, dynamic>>(
      '/blocks',
      data: {'blocked_user_id': blockedUserId},
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  Future<void> unblock(String blockId) async {
    await _api.delete<Map<String, dynamic>>(
      '/blocks/$blockId',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }
}

final blockServiceProvider = Provider<BlockService>((ref) {
  return BlockService(ref.watch(apiClientProvider));
});
