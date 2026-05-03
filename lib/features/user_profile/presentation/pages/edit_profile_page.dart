import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
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
  late bool _hasOwnTransport;
  late final Set<String> _selectedInterests;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authProvider).user?.touristProfile;
    _fullNameController = TextEditingController(text: profile?.fullName ?? '');
    _hasOwnTransport = profile?.hasOwnTransport ?? false;
    _selectedInterests = {...?profile?.interests};
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .updateTouristProfile(
          fullName: _fullNameController.text.trim(),
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
      context.pop();
      return;
    }

    final message =
        ref.read(authProvider).errorMessage ?? 'No se pudo actualizar perfil.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preferencias reales', style: theme.textTheme.displayLarge),
              const SizedBox(height: 8),
              Text(
                'Estos datos se guardan en tu perfil turista del backend y alimentan futuras personalizaciones.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
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
                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: InterestsSelector.availableInterests.map((interest) {
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
    );
  }
}
