import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/auth_state.dart';
import 'package:pair/core/storage/token_storage.dart';
import 'package:pair/core/widgets/route_stub_screen.dart';
import 'package:pair/features/auth/screens/login_screen.dart';
import 'package:pair/features/auth/screens/signup_screen.dart';
import 'package:pair/features/auth/screens/splash_screen.dart';
import 'package:pair/features/onboarding/screens/goal_category_screen.dart';
import 'package:pair/features/onboarding/screens/goal_detail_screen.dart';
import 'package:pair/features/onboarding/screens/matching_prefs_screen.dart';
import 'package:pair/features/onboarding/screens/profile_setup_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);

  ref.listen(authTokenProvider, (_, __) => refresh.notifyAuthChanged());

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) async {
      final hasToken = await tokenStorage.hasToken();
      final location = state.matchedLocation;
      final isPublic = AppRoutes.publicRoutes.contains(location);

      if (!hasToken && !isPublic) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.goalCategory,
        name: 'goal-category',
        builder: (context, state) => const GoalCategoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.goalDetail,
        name: 'goal-detail',
        builder: (context, state) => const GoalDetailScreen(),
      ),
      GoRoute(
        path: AppRoutes.matchingPrefs,
        name: 'matching-prefs',
        builder: (context, state) => const MatchingPrefsScreen(),
      ),
      GoRoute(
        path: AppRoutes.findingMatch,
        name: 'finding-match',
        builder: (context, state) =>
            const RouteStubScreen(routeName: 'finding-match'),
      ),
      GoRoute(
        path: AppRoutes.matchFound,
        name: 'match-found',
        builder: (context, state) =>
            const RouteStubScreen(routeName: 'match-found'),
      ),
      GoRoute(
        path: AppRoutes.podHome,
        name: 'pod-home',
        builder: (context, state) =>
            const RouteStubScreen(routeName: 'pod-home'),
      ),
      GoRoute(
        path: AppRoutes.podSettings,
        name: 'pod-settings',
        builder: (context, state) =>
            const RouteStubScreen(routeName: 'pod-settings'),
      ),
      GoRoute(
        path: AppRoutes.todoList,
        name: 'todo-list',
        builder: (context, state) =>
            const RouteStubScreen(routeName: 'todo-list'),
      ),
      GoRoute(
        path: AppRoutes.todoDetail,
        name: 'todo-detail',
        builder: (context, state) =>
            const RouteStubScreen(routeName: 'todo-detail'),
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        builder: (context, state) => const RouteStubScreen(routeName: 'chat'),
      ),
      GoRoute(
        path: AppRoutes.checkin,
        name: 'checkin',
        builder: (context, state) =>
            const RouteStubScreen(routeName: 'checkin'),
      ),
      GoRoute(
        path: AppRoutes.streakDetail,
        name: 'streak-detail',
        builder: (context, state) =>
            const RouteStubScreen(routeName: 'streak-detail'),
      ),
      GoRoute(
        path: AppRoutes.streakRecovery,
        name: 'streak-recovery',
        builder: (context, state) =>
            const RouteStubScreen(routeName: 'streak-recovery'),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) =>
            const RouteStubScreen(routeName: 'profile'),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        name: 'notification-settings',
        builder: (context, state) =>
            const RouteStubScreen(routeName: 'notification-settings'),
      ),
      GoRoute(
        path: AppRoutes.blockedUsers,
        name: 'blocked-users',
        builder: (context, state) =>
            const RouteStubScreen(routeName: 'blocked-users'),
      ),
      GoRoute(
        path: AppRoutes.reportForm,
        name: 'report-form',
        builder: (context, state) =>
            const RouteStubScreen(routeName: 'report-form'),
      ),
      GoRoute(
        path: AppRoutes.accountSettings,
        name: 'account-settings',
        builder: (context, state) =>
            const RouteStubScreen(routeName: 'account-settings'),
      ),
    ],
  );
});
