import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/map/presentation/pages/map_screen.dart';
import '../../features/onboarding/presentation/pages/vibe_selection_page.dart';
import '../../features/itinerary/presentation/pages/itinerary_detail_page.dart';
import '../../features/chat_ai/presentation/pages/chat_screen.dart';
import '../../features/user_profile/presentation/pages/profile_screen.dart';
import '../../features/map/presentation/pages/poi_detail_full_page.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      name: AppRouteNames.login,
      builder: (context, state) => const LoginPage(),
    ),
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
      path: AppRoutes.onboarding,
      name: AppRouteNames.onboarding,
      builder: (context, state) => const VibeSelectionPage(),
    ),

    GoRoute(
      path: AppRoutes.itineraryDetail,
      name: AppRouteNames.itineraryDetail,
      builder: (context, state) => const ItineraryDetailPage(),
    ),
    GoRoute(
      path: AppRoutes.chat,
      name: AppRouteNames.chat,
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      name: AppRouteNames.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.poiDetail,
      name: AppRouteNames.poiDetail,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PoiDetailFullPage(poiId: id);
      },
    ),
  ],
);
