import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/features/account/providers/notification_preferences_provider.dart';
import 'package:pair/features/onboarding/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushNotificationService {
  PushNotificationService(this._profileService);

  final ProfileService _profileService;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Firebase not configured; push notifications disabled.');
      }
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _initialized = true;
  }

  Future<void> registerTokenIfAuthenticated() async {
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) return;

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      final authorized = settings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!authorized) return;

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;

      await _profileService.updateFcmToken(token);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM token registration failed: $e');
      }
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final type = message.data['type'] as String?;
    if (type == null) return;

    final prefs = await SharedPreferences.getInstance();
    final storage = NotificationPreferencesStorage(prefs);
    if (!storage.isEnabled(type)) return;

    final title = message.notification?.title ?? 'Pair';
    final body = message.notification?.body ?? 'You have a new notification';

    const androidDetails = AndroidNotificationDetails(
      'pair_default',
      'Pair notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      details,
    );
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref.watch(profileServiceProvider));
});
