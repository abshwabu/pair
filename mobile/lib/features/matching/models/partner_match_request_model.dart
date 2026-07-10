class PartnerMatchUser {
  const PartnerMatchUser({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? avatarUrl;

  factory PartnerMatchUser.fromJson(Map<String, dynamic> json) {
    return PartnerMatchUser(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class PartnerMatchGoal {
  const PartnerMatchGoal({
    required this.id,
    required this.title,
    required this.targetDescription,
    required this.pace,
    required this.category,
  });

  final String id;
  final String title;
  final String targetDescription;
  final String pace;
  final String category;

  factory PartnerMatchGoal.fromJson(Map<String, dynamic> json) {
    return PartnerMatchGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      targetDescription: json['target_description'] as String? ?? '',
      pace: json['pace'] as String,
      category: json['category'] as String,
    );
  }
}

class PartnerMatchRequestModel {
  const PartnerMatchRequestModel({
    required this.id,
    required this.status,
    this.podId,
    this.requester,
    this.recipient,
    this.requesterGoal,
    this.recipientGoal,
  });

  final String id;
  final String status;
  final String? podId;
  final PartnerMatchUser? requester;
  final PartnerMatchUser? recipient;
  final PartnerMatchGoal? requesterGoal;
  final PartnerMatchGoal? recipientGoal;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isCancelled => status == 'cancelled';

  factory PartnerMatchRequestModel.fromJson(Map<String, dynamic> json) {
    return PartnerMatchRequestModel(
      id: json['id'] as String,
      status: json['status'] as String,
      podId: json['pod_id'] as String?,
      requester: json['requester'] != null
          ? PartnerMatchUser.fromJson(json['requester'] as Map<String, dynamic>)
          : null,
      recipient: json['recipient'] != null
          ? PartnerMatchUser.fromJson(json['recipient'] as Map<String, dynamic>)
          : null,
      requesterGoal: json['requester_goal'] != null
          ? PartnerMatchGoal.fromJson(
              json['requester_goal'] as Map<String, dynamic>,
            )
          : null,
      recipientGoal: json['recipient_goal'] != null
          ? PartnerMatchGoal.fromJson(
              json['recipient_goal'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
