import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_client.dart';
import 'package:pair/features/pods/models/pod_model.dart';

class PodLeaveResult {
  const PodLeaveResult({
    required this.podId,
    required this.status,
    this.leftAt,
  });

  final String podId;
  final String status;
  final String? leftAt;

  factory PodLeaveResult.fromJson(Map<String, dynamic> json) {
    return PodLeaveResult(
      podId: json['pod_id'] as String,
      status: json['status'] as String,
      leftAt: json['left_at'] as String?,
    );
  }
}

class PodService {
  PodService(this._api);

  final ApiClient _api;

  Future<String?> activePodId() async {
    final response = await _api.get<List<dynamic>>(
      '/pods',
      fromJsonT: (json) => (json as List).toList(),
    );

    for (final pod in response.data ?? []) {
      if (pod is Map<String, dynamic> && pod['status'] == 'active') {
        return pod['id'] as String;
      }
    }
    return null;
  }

  Future<PodDetailModel> getPod(String podId) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/pods/$podId',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return PodDetailModel.fromJson(response.data!);
  }

  Future<PodLeaveResult> leavePod(String podId) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/pods/$podId/leave',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return PodLeaveResult.fromJson(response.data!);
  }
}

final podServiceProvider = Provider<PodService>((ref) {
  return PodService(ref.watch(apiClientProvider));
});
