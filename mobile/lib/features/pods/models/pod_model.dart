class PodMemberUser {
  const PodMemberUser({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? avatarUrl;

  factory PodMemberUser.fromJson(Map<String, dynamic> json) {
    return PodMemberUser(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class PodMemberGoal {
  const PodMemberGoal({
    required this.id,
    required this.category,
    required this.title,
    required this.targetDescription,
    required this.pace,
  });

  final String id;
  final String category;
  final String title;
  final String targetDescription;
  final String pace;

  factory PodMemberGoal.fromJson(Map<String, dynamic> json) {
    return PodMemberGoal(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      targetDescription: json['target_description'] as String,
      pace: json['pace'] as String,
    );
  }
}

class PodMemberModel {
  const PodMemberModel({
    required this.user,
    required this.goal,
    this.joinedAt,
    this.leftAt,
  });

  final PodMemberUser user;
  final PodMemberGoal goal;
  final String? joinedAt;
  final String? leftAt;

  bool get isActive => leftAt == null;

  factory PodMemberModel.fromJson(Map<String, dynamic> json) {
    return PodMemberModel(
      user: PodMemberUser.fromJson(json['user'] as Map<String, dynamic>),
      goal: PodMemberGoal.fromJson(json['goal'] as Map<String, dynamic>),
      joinedAt: json['joined_at'] as String?,
      leftAt: json['left_at'] as String?,
    );
  }
}

class PodStreakModel {
  const PodStreakModel({
    required this.currentStreak,
    required this.bestStreak,
    this.lastCheckInDate,
  });

  final int currentStreak;
  final int bestStreak;
  final String? lastCheckInDate;

  factory PodStreakModel.fromJson(Map<String, dynamic> json) {
    return PodStreakModel(
      currentStreak: json['current_streak'] as int? ?? 0,
      bestStreak: json['best_streak'] as int? ?? 0,
      lastCheckInDate: json['last_check_in_date'] as String?,
    );
  }
}

class PodDetailModel {
  const PodDetailModel({
    required this.id,
    required this.goalCategory,
    required this.status,
    required this.capacity,
    required this.members,
    this.streak,
  });

  final String id;
  final String goalCategory;
  final String status;
  final int capacity;
  final List<PodMemberModel> members;
  final PodStreakModel? streak;

  PodMemberModel? activePartnerFor(String currentUserId) {
    for (final member in members) {
      if (member.isActive && member.user.id != currentUserId) {
        return member;
      }
    }
    return null;
  }

  factory PodDetailModel.fromJson(Map<String, dynamic> json) {
    return PodDetailModel(
      id: json['id'] as String,
      goalCategory: json['goal_category'] as String,
      status: json['status'] as String,
      capacity: json['capacity'] as int? ?? 2,
      members: (json['members'] as List<dynamic>)
          .map((m) => PodMemberModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      streak: json['streak'] != null
          ? PodStreakModel.fromJson(json['streak'] as Map<String, dynamic>)
          : null,
    );
  }
}
