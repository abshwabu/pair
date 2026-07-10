import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class NotificationTypes {
  static const newMessage = 'new_message';
  static const checkinNudge = 'checkin_nudge';
  static const streakBroken = 'streak_broken';
  static const matchFound = 'match_found';

  static const all = [
    newMessage,
    checkinNudge,
    streakBroken,
    matchFound,
  ];

  static String label(String type) => switch (type) {
        newMessage => 'New messages',
        checkinNudge => 'Check-in nudges',
        streakBroken => 'Streak broken alerts',
        matchFound => 'Match found',
        _ => type,
      };

  static String description(String type) => switch (type) {
        newMessage => 'When your partner sends a chat message',
        checkinNudge => 'When your partner checks in and you have not',
        streakBroken => 'When your pod streak is reset',
        matchFound => 'When you are matched with a new partner',
        _ => '',
      };

  static String prefKey(String type) => 'notification_enabled_$type';
}

class NotificationPreferencesStorage {
  NotificationPreferencesStorage(this._prefs);

  final SharedPreferences _prefs;

  bool isEnabled(String type) {
    return _prefs.getBool(NotificationTypes.prefKey(type)) ?? true;
  }

  Future<void> setEnabled(String type, bool enabled) async {
    await _prefs.setBool(NotificationTypes.prefKey(type), enabled);
  }
}

final notificationPreferencesStorageProvider =
    FutureProvider<NotificationPreferencesStorage>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return NotificationPreferencesStorage(prefs);
});

final notificationPreferencesProvider =
    StateNotifierProvider<NotificationPreferencesNotifier, Map<String, bool>>(
  (ref) => NotificationPreferencesNotifier(ref),
);

class NotificationPreferencesNotifier extends StateNotifier<Map<String, bool>> {
  NotificationPreferencesNotifier(this._ref) : super({}) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final storage = await _ref.read(notificationPreferencesStorageProvider.future);
    state = {
      for (final type in NotificationTypes.all) type: storage.isEnabled(type),
    };
  }

  Future<void> setEnabled(String type, bool enabled) async {
    final storage =
        await _ref.read(notificationPreferencesStorageProvider.future);
    await storage.setEnabled(type, enabled);
    state = {...state, type: enabled};
  }
}
