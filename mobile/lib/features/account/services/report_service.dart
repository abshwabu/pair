import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_client.dart';

class ReportService {
  ReportService(this._api);

  final ApiClient _api;

  Future<void> submitReport({
    required String reportedUserId,
    required String reason,
    String? podId,
  }) async {
    await _api.post<Map<String, dynamic>>(
      '/reports',
      data: {
        'reported_user_id': reportedUserId,
        'reason': reason,
        if (podId != null) 'pod_id': podId,
      },
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }
}

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(ref.watch(apiClientProvider));
});
