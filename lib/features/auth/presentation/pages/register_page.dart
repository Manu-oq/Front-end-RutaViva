import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/custom_button.dart';
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

    setState(() => _errorMessage = null);

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crea tu cuenta turista',
                    style: theme.textTheme.displayLarge?.copyWith(height: 1.0),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Estos datos se envían al backend para crear tu usuario y perfil turista. Tus intereses ayudan a personalizar búsquedas e itinerarios.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _errorMessage = null),
                            ),
                          ],
                        ),
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
                      if ((value ?? '').length < 6) {
                        return 'Usa al menos 6 caracteres.';
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
                  const SizedBox(height: 32),
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
    );
  }
}
