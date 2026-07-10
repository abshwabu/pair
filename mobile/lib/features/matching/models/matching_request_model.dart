class MatchingRequestModel {
  const MatchingRequestModel({
    required this.id,
    required this.status,
    this.podId,
  });

  final String id;
  final String status;
  final String? podId;

  bool get isOpen => status == 'open';
  bool get isMatched => status == 'matched';
  bool get isCancelled => status == 'cancelled';

  factory MatchingRequestModel.fromJson(Map<String, dynamic> json) {
    return MatchingRequestModel(
      id: json['id'] as String,
      status: json['status'] as String,
      podId: json['pod_id'] as String?,
    );
  }
}
