import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/bookmarks/presentation/pages/bookmarks_page.dart';
import '../../features/chat_ai/presentation/pages/chat_screen.dart';
import '../../features/entrepreneur/presentation/pages/entrepreneur_dashboard_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/widgets/mist_navigation.dart';
import '../../features/itinerary/presentation/pages/itinerary_detail_page.dart';
import '../../features/itinerary/presentation/pages/itinerary_history_page.dart';
import '../../features/map/presentation/pages/create_poi_page.dart';
import '../../features/map/presentation/pages/edit_poi_page.dart';
import '../../features/map/presentation/pages/map_screen.dart';
import '../../features/map/presentation/pages/poi_detail_full_page.dart';
import '../../features/onboarding/presentation/pages/vibe_selection_page.dart';
import '../../features/user_profile/presentation/pages/edit_profile_page.dart';
import '../../features/user_profile/presentation/pages/profile_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
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
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRouteNames.onboarding,
        builder: (context, state) => const VibeSelectionPage(),
      ),
      GoRoute(
        path: AppRoutes.itineraryDetail,
        name: AppRouteNames.itineraryDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ItineraryDetailPage(itineraryId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: AppRouteNames.chat,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: AppRouteNames.editProfile,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.entrepreneur,
        name: AppRouteNames.entrepreneur,
        builder: (context, state) => const EntrepreneurDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.createPoi,
        name: AppRouteNames.createPoi,
        builder: (context, state) => const CreatePoiPage(),
      ),
      GoRoute(
        path: AppRoutes.editPoi,
        name: AppRouteNames.editPoi,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditPoiPage(poiId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.poiDetail,
        name: AppRouteNames.poiDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PoiDetailFullPage(poiId: id);
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
            path: AppRoutes.bookmarks,
            name: AppRouteNames.bookmarks,
            builder: (context, state) => const BookmarksPage(),
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
