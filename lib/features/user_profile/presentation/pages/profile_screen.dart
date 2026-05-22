import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/account_settings.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final displayName = user?.displayName ?? 'Viajero Ruta Viva';
    final profile = user?.touristProfile;
    final interests = profile?.interests ?? const <String>[];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark
                  ? theme.colorScheme.surfaceContainerLowest
                  : theme.colorScheme.surface,
              isDark
                  ? AppColors.deepForest
                  : AppColors.mint.withValues(alpha: 0.45),
              isDark
                  ? theme.colorScheme.surfaceContainerLowest
                  : theme.colorScheme.surface,
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(authProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverSafeArea(
                bottom: false,
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: AppResponsive.maxContentWidth(context),
                      ),
                      child: Padding(
                        padding: AppResponsive.pagePadding(context),
                        child: Column(
                          children: [
                            ProfileHeader(
                              displayName: displayName,
                              subtitle: user == null
                                  ? 'Sesión por restaurar'
                                  : user.isEntrepreneur
                                  ? 'Viajero y emprendedor'
                                  : 'Viajero conectado',
                              supportingText: user == null
                                  ? 'Inicia sesión para consultar rutas, reseñas y lugares guardados.'
                                  : _profileSummary(user.email, user.createdAt),
                              interests: interests,
                              accountStatus: authState.isAuthenticated
                                  ? 'Cuenta activa'
                                  : 'Sesión pendiente',
                            ),
                            const SizedBox(height: 18),
                            const AccountSettings(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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

  String _profileSummary(String email, DateTime createdAt) {
    return '$email · cuenta activa desde el ${_formatDate(createdAt)}';
  }
}
