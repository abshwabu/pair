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
      currentStreak: json['current_streak'] as int? ?? 0,
      bestStreak: json['best_streak'] as int? ?? 0,
      lastCheckInDate: json['last_check_in_date'] as String?,
      bothCheckedInToday: json['both_checked_in_today'] as bool? ?? false,
      checkedInToday: json['checked_in_today'] as bool? ?? false,
    );
  }
}
