import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../itinerary/presentation/providers/itinerary_provider.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../widgets/account_settings.dart';
import '../widgets/impact_section.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final mapState = ref.watch(mapProvider);
    final itinerary = ref.watch(itineraryProvider).current;
    final displayName = user?.displayName ?? 'Viajero Ruta Viva';
    final profile = user?.touristProfile;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(authProvider);
        },
        child: SingleChildScrollView(
          child: Column(
          children: [
            const SizedBox(height: 80),
            ProfileHeader(
              displayName: displayName,
              subtitle: user == null
                  ? 'SESIÓN NO RESTAURADA'
                  : user.isEntrepreneur
                  ? 'VIAJERO Y EMPRENDEDOR'
                  : 'VIAJERO CONECTADO',
              supportingText: user == null
                  ? 'Inicia sesión para consultar rutas, reviews y POIs reales del backend.'
                  : _profileSummary(
                      user.email,
                      user.createdAt,
                      profile?.interests ?? const [],
                    ),
            ),
            const SizedBox(height: 32),
            ImpactSection(
              loadedPois: mapState.points.length,
              itinerarySteps: itinerary?.steps.length ?? 0,
              hasActiveSession: authState.isAuthenticated,
            ),
            const SizedBox(height: 32),
            const AccountSettings(),
            const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _profileSummary(
    String email,
    DateTime createdAt,
    List<String> interests,
  ) {
    final interestsText = interests.isEmpty
        ? 'sin intereses configurados'
        : interests.take(3).join(', ');
    return 'Cuenta activa: $email. Creada el ${_formatDate(createdAt)}. Intereses: $interestsText.';
  }
}
