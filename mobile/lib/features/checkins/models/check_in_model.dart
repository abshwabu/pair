import 'package:pair/features/checkins/models/streak_model.dart';

class CheckInUser {
  const CheckInUser({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? avatarUrl;

  factory CheckInUser.fromJson(Map<String, dynamic> json) {
    return CheckInUser(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class CheckInModel {
  const CheckInModel({
    required this.id,
    required this.podId,
    required this.user,
    required this.checkInDate,
    this.note,
    this.createdAt,
  });

  final String id;
  final String podId;
  final CheckInUser user;
  final String checkInDate;
  final String? note;
  final DateTime? createdAt;

  factory CheckInModel.fromJson(Map<String, dynamic> json) {
    return CheckInModel(
      id: json['id'] as String,
      podId: json['pod_id'] as String,
      user: CheckInUser.fromJson(json['user'] as Map<String, dynamic>),
      checkInDate: json['check_in_date'] as String,
      note: json['note'] as String?,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value as String);
  }
}

class CheckInDayGroup {
  const CheckInDayGroup({
    required this.date,
    required this.checkIns,
  });

  final String date;
  final List<CheckInModel> checkIns;

  bool get bothCheckedIn {
    final userIds = checkIns.map((checkIn) => checkIn.user.id).toSet();
    return userIds.length >= 2;
  }

  bool get onlyOneCheckedIn => checkIns.isNotEmpty && !bothCheckedIn;

  static List<CheckInDayGroup> groupByDate(List<CheckInModel> checkIns) {
    final byDate = <String, List<CheckInModel>>{};

    for (final checkIn in checkIns) {
      byDate.putIfAbsent(checkIn.checkInDate, () => []).add(checkIn);
    }

    final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return dates
        .map((date) => CheckInDayGroup(date: date, checkIns: byDate[date]!))
        .toList();
  }
}

class CheckInResult {
  const CheckInResult({
    required this.checkIn,
    required this.streak,
  });

  final CheckInModel checkIn;
  final StreakModel streak;
}
