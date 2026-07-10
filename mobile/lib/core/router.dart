import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/auth_state.dart';
import 'package:pair/core/storage/token_storage.dart';
import 'package:pair/core/widgets/route_stub_screen.dart';
import 'package:pair/features/auth/screens/login_screen.dart';
import 'package:pair/features/auth/screens/signup_screen.dart';
import 'package:pair/features/auth/screens/splash_screen.dart';
import 'package:pair/features/matching/screens/match_request_pending_screen.dart';
import 'package:pair/features/matching/screens/match_requests_screen.dart';
import 'package:pair/features/matching/screens/finding_match_screen.dart';
import 'package:pair/features/matching/screens/match_found_screen.dart';
import 'package:pair/features/onboarding/screens/goal_category_screen.dart';
import 'package:pair/features/onboarding/screens/goal_detail_screen.dart';
import 'package:pair/features/onboarding/screens/goal_list_screen.dart';
import 'package:pair/features/onboarding/screens/matching_prefs_screen.dart';
import 'package:pair/features/onboarding/screens/profile_setup_screen.dart';
import 'package:pair/features/pods/screens/pod_home_screen.dart';
import 'package:pair/features/pods/screens/pod_settings_screen.dart';
import 'package:pair/features/account/screens/account_settings_screen.dart';
import 'package:pair/features/account/screens/blocked_users_screen.dart';
import 'package:pair/features/account/screens/notification_settings_screen.dart';
import 'package:pair/features/account/screens/profile_edit_screen.dart';
import 'package:pair/features/account/screens/profile_screen.dart';
import 'package:pair/features/account/screens/report_form_screen.dart';
import 'package:pair/features/checkins/screens/streak_detail_screen.dart';
import 'package:pair/features/checkins/screens/streak_recovery_screen.dart';
import 'package:pair/features/chat/screens/chat_screen.dart';
import 'package:pair/features/todos/screens/todo_detail_screen.dart';
import 'package:pair/features/todos/screens/todo_list_screen.dart';

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
        path: AppRoutes.goalList,
        name: 'goal-list',
        builder: (context, state) => const GoalListScreen(),
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
        builder: (context, state) => const FindingMatchScreen(),
      ),
      GoRoute(
        path: AppRoutes.matchRequestPending,
        name: 'match-request-pending',
        builder: (context, state) => const MatchRequestPendingScreen(),
      ),
      GoRoute(
        path: AppRoutes.matchRequests,
        name: 'match-requests',
        builder: (context, state) => const MatchRequestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.matchFound,
        name: 'match-found',
        builder: (context, state) {
          final podId = AppRoutes.podIdFrom(state);
          if (podId == null) {
            return const RouteStubScreen(routeName: 'match-found');
          }
          return MatchFoundScreen(podId: podId);
        },
      ),
      GoRoute(
        path: AppRoutes.podHome,
        name: 'pod-home',
        builder: (context, state) {
          final podId = AppRoutes.podIdFrom(state);
          if (podId == null) {
            return const RouteStubScreen(routeName: 'pod-home');
          }
          return PodHomeScreen(podId: podId);
        },
      ),
      GoRoute(
        path: AppRoutes.podSettings,
        name: 'pod-settings',
        builder: (context, state) {
          final podId = AppRoutes.podIdFrom(state);
          if (podId == null) {
            return const RouteStubScreen(routeName: 'pod-settings');
          }
          return PodSettingsScreen(podId: podId);
        },
      ),
      GoRoute(
        path: AppRoutes.todoList,
        name: 'todo-list',
        builder: (context, state) {
          final podId = AppRoutes.podIdFrom(state);
          if (podId == null) {
            return const RouteStubScreen(routeName: 'todo-list');
          }
          return TodoListScreen(podId: podId);
        },
      ),
      GoRoute(
        path: AppRoutes.todoDetail,
        name: 'todo-detail',
        builder: (context, state) {
          final podId = AppRoutes.podIdFrom(state);
          final todoId = AppRoutes.todoIdFrom(state);
          if (podId == null || todoId == null) {
            return const RouteStubScreen(routeName: 'todo-detail');
          }
          return TodoDetailScreen(podId: podId, todoId: todoId);
        },
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        builder: (context, state) {
          final podId = AppRoutes.podIdFrom(state);
          if (podId == null) {
            return const RouteStubScreen(routeName: 'chat');
          }
          return ChatScreen(podId: podId);
        },
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
        builder: (context, state) {
          final podId = AppRoutes.podIdFrom(state);
          if (podId == null) {
            return const RouteStubScreen(routeName: 'streak-detail');
          }
          return StreakDetailScreen(podId: podId);
        },
      ),
      GoRoute(
        path: AppRoutes.streakRecovery,
        name: 'streak-recovery',
        builder: (context, state) {
          final podId = AppRoutes.podIdFrom(state);
          if (podId == null) {
            return const RouteStubScreen(routeName: 'streak-recovery');
          }
          return StreakRecoveryScreen(podId: podId);
        },
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        name: 'profile-edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        name: 'notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.blockedUsers,
        name: 'blocked-users',
        builder: (context, state) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: AppRoutes.reportForm,
        name: 'report-form',
        builder: (context, state) {
          final reportedUserId = AppRoutes.reportedUserIdFrom(state);
          if (reportedUserId == null) {
            return const RouteStubScreen(routeName: 'report-form');
          }
          return ReportFormScreen(
            reportedUserId: reportedUserId,
            podId: AppRoutes.podIdFrom(state),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.accountSettings,
        name: 'account-settings',
        builder: (context, state) => const AccountSettingsScreen(),
      ),
    ],
  );
});
