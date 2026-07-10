import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/features/account/services/block_service.dart';

class BlockedUsersState {
  const BlockedUsersState({
    this.blocks = const [],
    this.isLoading = false,
    this.unblockingId,
    this.error,
    this.hasLoaded = false,
  });

  final List<BlockModel> blocks;
  final bool isLoading;
  final String? unblockingId;
  final String? error;
  final bool hasLoaded;

  BlockedUsersState copyWith({
    List<BlockModel>? blocks,
    bool? isLoading,
    String? unblockingId,
    String? error,
    bool? hasLoaded,
    bool clearUnblocking = false,
    bool clearError = false,
  }) {
    return BlockedUsersState(
      blocks: blocks ?? this.blocks,
      isLoading: isLoading ?? this.isLoading,
      unblockingId: clearUnblocking ? null : unblockingId ?? this.unblockingId,
      error: clearError ? null : error ?? this.error,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class BlockedUsersNotifier extends StateNotifier<BlockedUsersState> {
  BlockedUsersNotifier(this._ref) : super(const BlockedUsersState()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final blocks = await _ref.read(blockServiceProvider).listBlocks();
      state = state.copyWith(
        blocks: blocks,
        isLoading: false,
        hasLoaded: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load blocked users.',
      );
    }
  }

  Future<String?> unblock(String blockId) async {
    state = state.copyWith(unblockingId: blockId, clearError: true);

    try {
      await _ref.read(blockServiceProvider).unblock(blockId);
      state = state.copyWith(
        blocks: state.blocks.where((block) => block.id != blockId).toList(),
        clearUnblocking: true,
      );
      return null;
    } on ApiException catch (e) {
      state = state.copyWith(clearUnblocking: true, error: e.message);
      return e.message;
    } catch (_) {
      state = state.copyWith(
        clearUnblocking: true,
        error: 'Unable to unblock user.',
      );
      return 'Unable to unblock user.';
    }
  }
}

final blockedUsersProvider =
    StateNotifierProvider.autoDispose<BlockedUsersNotifier, BlockedUsersState>(
  (ref) => BlockedUsersNotifier(ref),
);
