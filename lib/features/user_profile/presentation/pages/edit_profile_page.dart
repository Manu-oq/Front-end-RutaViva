import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/authenticated_network_image.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../onboarding/presentation/widgets/interests_selector.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _avatarUrlController;
  late bool _hasOwnTransport;
  late final Set<String> _selectedInterests;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    final profile = user?.touristProfile;
    _fullNameController = TextEditingController(
      text: profile?.fullName ?? user?.displayName ?? '',
    );
    _emailController = TextEditingController(text: user?.email ?? '');
    _avatarUrlController = TextEditingController(text: user?.avatarUrl ?? '');
    _hasOwnTransport = profile?.hasOwnTransport ?? false;
    _selectedInterests = {...?profile?.interests};
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _errorMessage = null);

    final success = await ref
        .read(authProvider.notifier)
        .updateTouristProfile(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          avatarUrl: _avatarUrlController.text.trim(),
          hasOwnTransport: _hasOwnTransport,
          interests: _selectedInterests.toList()..sort(),
        );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perfil actualizado.')));
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(AppRouteNames.profile);
      }
      return;
    }

    final message =
        ref.read(authProvider).errorMessage ?? 'No se pudo actualizar perfil.';
    setState(() => _errorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final isMobile = AppResponsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRouteName: AppRouteNames.profile),
        title: const Text('Editar perfil'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.brightness == Brightness.dark
                  ? theme.colorScheme.surfaceContainerLowest
                  : theme.colorScheme.surface,
              theme.brightness == Brightness.dark
                  ? AppColors.deepForest
                  : AppColors.mint.withValues(alpha: 0.42),
              theme.brightness == Brightness.dark
                  ? theme.colorScheme.surfaceContainerLowest
                  : theme.colorScheme.surface,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: AppResponsive.pagePadding(context),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppResponsive.maxContentWidth(context),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferencias reales',
                      style: isMobile
                          ? theme.textTheme.displaySmall
                          : theme.textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estos datos ayudan a Ara a personalizar tus rutas y recomendaciones.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null) ...[
                      ErrorBanner(
                        message: _errorMessage!,
                        onDismiss: () => setState(() => _errorMessage = null),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _AvatarPreviewField(controller: _avatarUrlController),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().length < 3) {
                          return 'Ingresa un nombre válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tengo transporte propio'),
                      subtitle: const Text(
                        'Se usa para futuras rutas y recomendaciones.',
                      ),
                      value: _hasOwnTransport,
                      onChanged: authState.isLoading
                          ? null
                          : (value) => setState(() => _hasOwnTransport = value),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Intereses',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: InterestsSelector.availableInterests.map((
                        interest,
                      ) {
                        final selected = _selectedInterests.contains(interest);
                        return FilterChip(
                          label: Text(interest),
                          selected: selected,
                          onSelected: authState.isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    if (value) {
                                      _selectedInterests.add(interest);
                                    } else {
                                      _selectedInterests.remove(interest);
                                    }
                                  });
                                },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    CustomButton(
                      text: 'Guardar cambios',
                      isLoading: authState.isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarPreviewField extends StatefulWidget {
  final TextEditingController controller;

  const _AvatarPreviewField({required this.controller});

  @override
  State<_AvatarPreviewField> createState() => _AvatarPreviewFieldState();
}

class _AvatarPreviewFieldState extends State<_AvatarPreviewField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = widget.controller.text.trim();
    return Row(
      children: [
        ClipOval(
          child: Container(
            width: 68,
            height: 68,
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: url.isEmpty
                ? Icon(Icons.person_rounded, color: theme.colorScheme.primary)
                : AuthenticatedNetworkImage(
                    imageUrl: url,
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    errorBuilder: (_) => Icon(
                      Icons.person_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: TextFormField(
            controller: widget.controller,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Imagen de perfil opcional',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.image_outlined),
            ),
          ),
        ),
      ],
    );
  }
}
