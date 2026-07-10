import 'package:go_router/go_router.dart';

/// Central route path constants.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const profileSetup = '/profile-setup';
  static const goalCategory = '/goal-category';
  static const goalDetail = '/goal-detail';
  static const matchingPrefs = '/matching-prefs';
  static const findingMatch = '/finding-match';
  static const matchFound = '/match-found';
  static const podHome = '/pod-home';
  static const podSettings = '/pod-settings';
  static const todoList = '/todo-list';
  static const todoDetail = '/todo-detail';
  static const chat = '/chat';
  static const checkin = '/checkin';
  static const streakDetail = '/streak-detail';
  static const streakRecovery = '/streak-recovery';
  static const profile = '/profile';
  static const notificationSettings = '/notification-settings';
  static const blockedUsers = '/blocked-users';
  static const reportForm = '/report-form';
  static const accountSettings = '/account-settings';

  static const publicRoutes = {splash, login, signup};

  static String matchFoundPath(String podId) => '$matchFound?podId=$podId';

  static String podHomePath(String podId) => '$podHome?podId=$podId';

  static String podSettingsPath(String podId) => '$podSettings?podId=$podId';

  static String todoListPath(String podId) => '$todoList?podId=$podId';

  static String todoDetailPath(String podId, String todoId) =>
      '$todoDetail?podId=$podId&todoId=$todoId';

  static String chatPath(String podId) => '$chat?podId=$podId';

  static String streakDetailPath(String podId) => '$streakDetail?podId=$podId';

  static String streakRecoveryPath(String podId) =>
      '$streakRecovery?podId=$podId';

  static String reportFormPath(String podId) => '$reportForm?podId=$podId';

  static String? podIdFrom(GoRouterState state) => state.uri.queryParameters['podId'];

  static String? todoIdFrom(GoRouterState state) =>
      state.uri.queryParameters['todoId'];

  static const allStubs = [
    splash,
    login,
    signup,
    profileSetup,
    goalCategory,
    goalDetail,
    matchingPrefs,
    findingMatch,
    matchFound,
    podHome,
    podSettings,
    todoList,
    todoDetail,
    chat,
    checkin,
    streakDetail,
    streakRecovery,
    profile,
    notificationSettings,
    blockedUsers,
    reportForm,
    accountSettings,
  ];
}
