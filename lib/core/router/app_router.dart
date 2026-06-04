import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/bookmarks/presentation/pages/bookmarks_page.dart';
import '../../features/chat_ai/presentation/pages/chat_screen.dart';
import '../../features/entrepreneur/presentation/pages/entrepreneur_dashboard_page.dart';
import '../../features/entrepreneur/presentation/pages/poi_dashboard_page.dart';
import '../../features/entrepreneur/presentation/pages/poi_posts_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/widgets/mist_navigation.dart';
import '../../features/itinerary/presentation/pages/itinerary_detail_page.dart';
import '../../features/itinerary/presentation/pages/itinerary_history_page.dart';
import '../../features/map/presentation/pages/create_poi_page.dart';
import '../../features/map/presentation/pages/edit_poi_page.dart';
import '../../features/map/presentation/pages/map_screen.dart';
import '../../features/map/presentation/pages/my_contributions_page.dart';
import '../../features/map/presentation/pages/poi_detail_full_page.dart';
import '../../features/onboarding/presentation/pages/vibe_selection_page.dart';
import '../../features/user_profile/presentation/pages/edit_profile_page.dart';
import '../../features/user_profile/presentation/pages/profile_screen.dart';
import '../utils/app_durations.dart';
import 'app_routes.dart';

Page<dynamic> _fadeTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: AppDurations.medium,
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRefresh = _GoRouterRefreshStream();
  ref
    ..onDispose(authRefresh.dispose)
    ..listen<AuthState>(authProvider, (previous, next) => authRefresh.notify());

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isPublicAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      final isAuthenticated = authState.isAuthenticated;
      final isRestoringSession = authState.isLoading && authState.token != null;

      if (isRestoringSession) {
        return null;
      }

      if (!isAuthenticated && !isPublicAuthRoute) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isPublicAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: AppRouteNames.login,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(key: state.pageKey, child: const LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRouteNames.register,
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRouteNames.onboarding,
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: const VibeSelectionPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.itineraryDetail,
        name: AppRouteNames.itineraryDetail,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _fadeTransitionPage(
            key: state.pageKey,
            child: ItineraryDetailPage(itineraryId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.bookmarks,
        name: AppRouteNames.bookmarks,
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: const BookmarksPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: AppRouteNames.editProfile,
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: const EditProfilePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.entrepreneur,
        name: AppRouteNames.entrepreneur,
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: const EntrepreneurDashboardPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.poiDashboard,
        name: AppRouteNames.poiDashboard,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _fadeTransitionPage(
            key: state.pageKey,
            child: PoiDashboardPage(poiId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.poiPosts,
        name: AppRouteNames.poiPosts,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _fadeTransitionPage(
            key: state.pageKey,
            child: PoiPostsManagementPage(poiId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.createPoi,
        name: AppRouteNames.createPoi,
        pageBuilder: (context, state) {
          final creationType =
              state.uri.queryParameters['creationType'] ?? 'tourist';
          return _fadeTransitionPage(
            key: state.pageKey,
            child: CreatePoiPage(creationType: creationType),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.myContributions,
        name: AppRouteNames.myContributions,
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: const MyContributionsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.editPoi,
        name: AppRouteNames.editPoi,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _fadeTransitionPage(
            key: state.pageKey,
            child: EditPoiPage(poiId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.poiDetail,
        name: AppRouteNames.poiDetail,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _fadeTransitionPage(
            key: state.pageKey,
            child: PoiDetailFullPage(poiId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.focusedMap,
        name: AppRouteNames.focusedMap,
        pageBuilder: (context, state) {
          final fallbackRouteName = state.extra is String
              ? state.extra! as String
              : AppRouteNames.chat;
          return _fadeTransitionPage(
            key: state.pageKey,
            child: MapScreen(backFallbackRouteName: fallbackRouteName),
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => MistNavigation(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: AppRouteNames.home,
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.chat,
            name: AppRouteNames.chat,
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: AppRoutes.map,
            name: AppRouteNames.map,
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: AppRoutes.itineraryHistory,
            name: AppRouteNames.itineraryHistory,
            builder: (context, state) => const ItineraryHistoryPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: AppRouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

class _GoRouterRefreshStream extends ChangeNotifier {
  void notify() => notifyListeners();
}
