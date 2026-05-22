import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/terms_and_conditions.dart';
import '../../../onboarding/presentation/providers/interests_provider.dart';
import '../../../onboarding/presentation/widgets/interests_selector.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _hasOwnTransport = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _termsError = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      setState(() {
        _termsError = true;
        _errorMessage = null;
      });
      final accepted = await showTermsAndConditionsDialog(context);
      if (!mounted) return;
      if (!accepted) {
        setState(
          () => _errorMessage =
              'Debes aceptar los términos y condiciones para crear tu cuenta.',
        );
        return;
      }
      setState(() {
        _acceptedTerms = true;
        _termsError = false;
      });
    }

    setState(() {
      _errorMessage = null;
      _termsError = false;
    });

    final selectedInterests = ref.read(interestsProvider);
    final success = await ref
        .read(authProvider.notifier)
        .registerTourist(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          hasOwnTransport: _hasOwnTransport,
          interests: selectedInterests,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      context.goNamed(AppRouteNames.home);
      return;
    }

    final message =
        ref.read(authProvider).errorMessage ?? 'No se pudo crear la cuenta.';
    setState(() => _errorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final isMobile = AppResponsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () => context.goNamed(AppRouteNames.login),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: AppResponsive.compactPagePadding(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crea tu cuenta turista',
                      style:
                          (isMobile
                                  ? theme.textTheme.displaySmall
                                  : theme.textTheme.displayLarge)
                              ?.copyWith(height: 1.0),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tus intereses ayudan a personalizar búsquedas, rutas e itinerarios.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    SizedBox(height: isMobile ? 20 : 28),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ErrorBanner(
                          message: _errorMessage!,
                          onDismiss: () => setState(() => _errorMessage = null),
                        ),
                      ),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().length < 3) {
                          return 'Ingresa tu nombre completo.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) {
                          return 'Ingresa tu correo.';
                        }
                        if (!email.contains('@')) {
                          return 'Correo inválido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').length < 8) {
                          return 'La contraseña debe tener al menos 8 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: Icon(Icons.lock_reset),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tengo transporte propio'),
                      subtitle: const Text(
                        'Se guarda en tu perfil turista para futuras recomendaciones.',
                      ),
                      value: _hasOwnTransport,
                      onChanged: authState.isLoading
                          ? null
                          : (value) => setState(() => _hasOwnTransport = value),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Intereses iniciales',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Puedes cambiarlos seleccionando o quitando etiquetas antes de crear tu cuenta.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    const InterestsSelector(),
                    SizedBox(height: isMobile ? 22 : 32),
                    TermsAcceptanceCard(
                      enabled: !authState.isLoading,
                      accepted: _acceptedTerms,
                      hasError: _termsError,
                      onOpenTerms: () async {
                        final accepted = await showTermsAndConditionsDialog(
                          context,
                        );
                        if (!mounted || !accepted) return;
                        setState(() {
                          _acceptedTerms = true;
                          _termsError = false;
                          _errorMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Crear cuenta y entrar',
                      isLoading: authState.isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: authState.isLoading
                            ? null
                            : () => context.goNamed(AppRouteNames.login),
                        child: const Text('Ya tengo cuenta'),
                      ),
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
