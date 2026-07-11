class StreakModel {
  const StreakModel({
    required this.currentStreak,
    required this.bestStreak,
    this.lastCheckInDate,
    required this.bothCheckedInToday,
    required this.checkedInToday,
  });

  final int currentStreak;
  final int bestStreak;
  final String? lastCheckInDate;
  final bool bothCheckedInToday;
  final bool checkedInToday;

  bool get isBroken => currentStreak == 0 && bestStreak > 0;

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    return StreakModel(
      currentStreak: _readInt(json['current_streak']),
      bestStreak: _readInt(json['best_streak']),
      lastCheckInDate: json['last_check_in_date'] as String?,
      bothCheckedInToday: _readBool(json['both_checked_in_today']),
      checkedInToday: _readBool(json['checked_in_today']),
    );
  }

  static int _readInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _readBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value == 'true' || value == '1';
    }
    return false;
  }
}
