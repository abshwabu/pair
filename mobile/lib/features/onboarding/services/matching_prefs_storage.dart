import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MatchingPrefs {
  const MatchingPrefs({
    required this.timezoneToleranceHours,
    required this.language,
  });

  final int timezoneToleranceHours;
  final String language;
}

class MatchingPrefsStorage {
  static const _toleranceKey = 'matching_timezone_tolerance_hours';
  static const _languageKey = 'matching_language';

  Future<void> save(MatchingPrefs prefs) async {
    final storage = await SharedPreferences.getInstance();
    await storage.setInt(_toleranceKey, prefs.timezoneToleranceHours);
    await storage.setString(_languageKey, prefs.language);
  }

  Future<MatchingPrefs?> load() async {
    final storage = await SharedPreferences.getInstance();
    final tolerance = storage.getInt(_toleranceKey);
    final language = storage.getString(_languageKey);
    if (tolerance == null || language == null) return null;
    return MatchingPrefs(
      timezoneToleranceHours: tolerance,
      language: language,
    );
  }
}

final matchingPrefsStorageProvider = Provider<MatchingPrefsStorage>(
  (ref) => MatchingPrefsStorage(),
);
