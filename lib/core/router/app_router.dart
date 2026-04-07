import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/map/presentation/pages/map_screen.dart';
import '../../features/onboarding/presentation/pages/vibe_selection_page.dart';
import '../../features/itinerary/presentation/pages/itinerary_detail_page.dart'; 
import '../../features/chat_ai/presentation/pages/chat_screen.dart';
import '../../features/user_profile/presentation/pages/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login', 
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/map',
      name: 'map',
      builder: (context, state) => const MapScreen(),
    ),

    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const VibeSelectionPage(),
    ),

    GoRoute(
      path: '/itinerary-detail',
      name: 'itinerary_detail',
      builder: (context, state) => const ItineraryDetailPage(),
    ),
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    ],
);