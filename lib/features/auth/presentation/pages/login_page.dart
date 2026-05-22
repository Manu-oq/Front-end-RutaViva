import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_banner.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _errorMessage = null);

    final success = await ref
        .read(authProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      context.goNamed(AppRouteNames.home);
      return;
    }

    final message =
        ref.read(authProvider).errorMessage ?? 'No se pudo iniciar sesión.';
    setState(() => _errorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final backgroundColors = isDark
        ? [
            theme.colorScheme.surfaceContainerLowest,
            AppColors.deepForest,
            AppColors.forest,
          ]
        : [theme.colorScheme.secondary, theme.colorScheme.primary];

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: backgroundColors,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.terrain, size: 64, color: Colors.white),
                    const SizedBox(height: 20),
                    Text(
                      'Bienvenido a Ruta Viva',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Inicia sesión para recuperar rutas reales, POIs cercanos, reviews e itinerarios personalizados.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ErrorBanner(
                          message: _errorMessage!,
                          onDismiss: () => setState(() => _errorMessage = null),
                        ),
                      ),
                    Card(
                      elevation: 0,
                      color: isDark
                          ? theme.colorScheme.surfaceContainerLow.withValues(
                              alpha: 0.96,
                            )
                          : Colors.white.withValues(alpha: 0.96),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                        side: BorderSide(
                          color: isDark
                              ? theme.colorScheme.outlineVariant
                              : Colors.transparent,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Entrar',
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
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
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if ((value ?? '').isEmpty) {
                                    return 'Ingresa tu contraseña.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              CustomButton(
                                text: 'Iniciar sesión',
                                isLoading: authState.isLoading,
                                onPressed: _submit,
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () => context.goNamed(
                                        AppRouteNames.register,
                                      ),
                                child: const Text('Crear una cuenta turista'),
                              ),
                            ],
                          ),
                        ),
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
