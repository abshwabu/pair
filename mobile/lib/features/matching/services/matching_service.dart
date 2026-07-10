import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_client.dart';
import 'package:pair/features/matching/models/matching_request_model.dart';

class MatchingService {
  MatchingService(this._api);

  final ApiClient _api;

  Future<MatchingRequestModel> createRequest({
    required String goalId,
    required int timezoneToleranceHours,
    String? targetGoalId,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/matching/request',
      data: {
        'goal_id': goalId,
        'timezone_tolerance_hours': timezoneToleranceHours,
        if (targetGoalId != null) 'target_goal_id': targetGoalId,
      },
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return MatchingRequestModel.fromJson(response.data!);
  }

  Future<MatchingRequestModel> getRequest(String id) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/matching/request/$id',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return MatchingRequestModel.fromJson(response.data!);
  }

  Future<MatchingRequestModel> cancelRequest(String id) async {
    final response = await _api.delete<Map<String, dynamic>>(
      '/matching/request/$id',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return MatchingRequestModel.fromJson(response.data!);
  }
}

final matchingServiceProvider = Provider<MatchingService>((ref) {
  return MatchingService(ref.watch(apiClientProvider));
});
