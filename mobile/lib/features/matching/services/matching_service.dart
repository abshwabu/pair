import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_client.dart';
import 'package:pair/features/matching/models/matching_request_model.dart';
import 'package:pair/features/matching/models/partner_match_request_model.dart';

class MatchingService {
  MatchingService(this._api);

  final ApiClient _api;

  Future<MatchingRequestModel> createRequest({
    required String goalId,
    required int timezoneToleranceHours,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/matching/request',
      data: {
        'goal_id': goalId,
        'timezone_tolerance_hours': timezoneToleranceHours,
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

  Future<PartnerMatchRequestModel> createPartnerRequest({
    required String goalId,
    required String targetGoalId,
    required int timezoneToleranceHours,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/matching/partner-requests',
      data: {
        'goal_id': goalId,
        'target_goal_id': targetGoalId,
        'timezone_tolerance_hours': timezoneToleranceHours,
      },
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return PartnerMatchRequestModel.fromJson(response.data!);
  }

  Future<List<PartnerMatchRequestModel>> listPartnerRequests({
    required String direction,
    bool pendingOnly = false,
  }) async {
    final response = await _api.get<List<dynamic>>(
      '/matching/partner-requests',
      queryParameters: {
        'direction': direction,
        if (pendingOnly) 'status': 'pending',
      },
      fromJsonT: (json) => (json as List).toList(),
    );

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PartnerMatchRequestModel.fromJson)
        .toList();
  }

  Future<PartnerMatchRequestModel> getPartnerRequest(String id) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/matching/partner-requests/$id',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return PartnerMatchRequestModel.fromJson(response.data!);
  }

  Future<PartnerMatchRequestModel> acceptPartnerRequest(String id) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/matching/partner-requests/$id/accept',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return PartnerMatchRequestModel.fromJson(response.data!);
  }

  Future<PartnerMatchRequestModel> declinePartnerRequest(String id) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/matching/partner-requests/$id/decline',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return PartnerMatchRequestModel.fromJson(response.data!);
  }

  Future<PartnerMatchRequestModel> cancelPartnerRequest(String id) async {
    final response = await _api.delete<Map<String, dynamic>>(
      '/matching/partner-requests/$id',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return PartnerMatchRequestModel.fromJson(response.data!);
  }
}

final matchingServiceProvider = Provider<MatchingService>((ref) {
  return MatchingService(ref.watch(apiClientProvider));
});
