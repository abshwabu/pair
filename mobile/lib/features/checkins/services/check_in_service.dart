import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_client.dart';
import 'package:pair/features/checkins/models/check_in_model.dart';
import 'package:pair/features/checkins/models/streak_model.dart';

class CheckInService {
  CheckInService(this._api);

  final ApiClient _api;

  Future<StreakModel> getStreak(String podId) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/pods/$podId/streak',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return StreakModel.fromJson(response.data!);
  }

  Future<List<CheckInModel>> listCheckIns(String podId) async {
    final response = await _api.get<List<dynamic>>(
      '/pods/$podId/check-ins',
      fromJsonT: (json) => (json as List).toList(),
    );

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CheckInModel.fromJson)
        .toList();
  }

  Future<CheckInResult> createCheckIn({
    required String podId,
    String? note,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/pods/$podId/check-ins',
      data: note != null && note.isNotEmpty ? {'note': note} : null,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );

    final streakJson = response.meta?['streak'] as Map<String, dynamic>?;
    if (streakJson == null) {
      throw const FormatException('Missing streak in check-in response');
    }

    return CheckInResult(
      checkIn: CheckInModel.fromJson(response.data!),
      streak: StreakModel.fromJson(streakJson),
    );
  }

  Future<void> nudgePartner(String podId) async {
    await _api.post<Map<String, dynamic>>(
      '/pods/$podId/nudge',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }
}

final checkInServiceProvider = Provider<CheckInService>((ref) {
  return CheckInService(ref.watch(apiClientProvider));
});
