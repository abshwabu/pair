import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_client.dart';

class BlockService {
  BlockService(this._api);

  final ApiClient _api;

  Future<void> blockUser(String blockedUserId) async {
    await _api.post<Map<String, dynamic>>(
      '/blocks',
      data: {'blocked_user_id': blockedUserId},
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }
}

final blockServiceProvider = Provider<BlockService>((ref) {
  return BlockService(ref.watch(apiClientProvider));
});
