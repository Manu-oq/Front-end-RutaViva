import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../data/repositories/poi_repository.dart';
import '../providers/map_provider.dart';

class CreatePoiPage extends ConsumerStatefulWidget {
  const CreatePoiPage({super.key});

  @override
  ConsumerState<CreatePoiPage> createState() => _CreatePoiPageState();
}

class _CreatePoiPageState extends ConsumerState<CreatePoiPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _imageUrlController = TextEditingController();
  late final TextEditingController _latController;
  late final TextEditingController _lonController;
  String _accessType = 'publico';
  final Set<int> _selectedCategoryIds = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final center = ref.read(mapProvider).center;
    _latController = TextEditingController(
      text: center.latitude.toStringAsFixed(6),
    );
    _lonController = TextEditingController(
      text: center.longitude.toStringAsFixed(6),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _imageUrlController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }
    if (_selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una categoría.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final poi = await ref
          .read(poiRepositoryProvider)
          .createPoi(
            nombre: _nameController.text.trim(),
            descripcion: _descriptionController.text.trim(),
            tipoAcceso: _accessType,
            telefonoPublico: _phoneController.text.trim(),
            emailPublico: _emailController.text.trim(),
            imageUrl: _imageUrlController.text.trim(),
            categoryIds: _selectedCategoryIds.toList()..sort(),
            latitude: double.parse(_latController.text.trim()),
            longitude: double.parse(_lonController.text.trim()),
          );

      await ref
          .read(mapProvider.notifier)
          .loadNearby(center: poi.toMapPoint().coordinates);
      ref.invalidate(myPoisProvider);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lugar creado correctamente.')),
      );
      context.goNamed(AppRouteNames.poiDetail, pathParameters: {'id': poi.id});
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'No se pudo crear el lugar.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      body: _PoiFormBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FormHero(
                              title: 'Comparte un lugar',
                              eyebrow: 'Nuevo aporte',
                              description:
                                  'Ayuda a otros viajeros a descubrir rincones, servicios o experiencias de La Araucanía.',
                              fallbackRouteName: AppRouteNames.profile,
                            ),
                            const SizedBox(height: 16),
                            _FormSection(
                              title: 'Información principal',
                              icon: Icons.place_rounded,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      labelText: 'Nombre del lugar',
                                      prefixIcon: Icon(Icons.place_outlined),
                                    ),
                                    validator: _nameValidator,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _descriptionController,
                                    minLines: 4,
                                    maxLines: 8,
                                    decoration: const InputDecoration(
                                      labelText: 'Descripción',
                                      alignLabelWithHint: true,
                                      hintText:
                                          'Cuenta qué lo hace especial, cómo llegar o qué deberían saber los visitantes.',
                                    ),
                                    validator: _descriptionValidator,
                                  ),
                                  const SizedBox(height: 14),
                                  _AccessTypeSelector(
                                    value: _accessType,
                                    onChanged: (value) =>
                                        setState(() => _accessType = value),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _FormSection(
                              title: 'Categorías',
                              icon: Icons.local_offer_rounded,
                              child: _CategorySelector(
                                categories: categories,
                                selectedCategoryIds: _selectedCategoryIds,
                                onToggle: _toggleCategory,
                                onRetry: () =>
                                    ref.invalidate(categoriesProvider),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _FormSection(
                              title: 'Ubicación',
                              icon: Icons.my_location_rounded,
                              child: _CoordinateFields(
                                latController: _latController,
                                lonController: _lonController,
                                validator: _coordinateValidator,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _FormSection(
                              title: 'Contacto e imagen',
                              icon: Icons.contact_phone_rounded,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      labelText: 'Teléfono público opcional',
                                      prefixIcon: Icon(Icons.phone_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Email público opcional',
                                      prefixIcon: Icon(Icons.email_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _imageUrlController,
                                    keyboardType: TextInputType.url,
                                    decoration: const InputDecoration(
                                      labelText: 'URL de imagen opcional',
                                      prefixIcon: Icon(Icons.image_outlined),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            CustomButton(
                              text: 'Publicar lugar',
                              isLoading: _isSubmitting,
                              onPressed: _submit,
                            ),
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

  void _toggleCategory(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedCategoryIds.add(id);
      } else {
        _selectedCategoryIds.remove(id);
      }
    });
  }

  String? _nameValidator(String? value) {
    if ((value ?? '').trim().length < 3) {
      return 'Ingresa un nombre válido.';
    }
    return null;
  }

  String? _descriptionValidator(String? value) {
    if ((value ?? '').trim().length < 20) {
      return 'La descripción debe tener al menos 20 caracteres.';
    }
    return null;
  }

  String? _coordinateValidator(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null) {
      return 'Coordenada inválida.';
    }
    return null;
  }
}

class _PoiFormBackground extends StatelessWidget {
  final Widget child;

  const _PoiFormBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            AppColors.mint.withValues(alpha: 0.42),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: child,
    );
  }
}

class _FormHero extends StatelessWidget {
  final String title;
  final String eyebrow;
  final String description;
  final String fallbackRouteName;
  const _FormHero({
    required this.title,
    required this.eyebrow,
    required this.description,
    required this.fallbackRouteName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepForest, AppColors.forest, AppColors.moss],
        ),
        boxShadow: AppColors.liftedShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -40,
            child: Container(
              width: 142,
              height: 142,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBackButton(
                fallbackRouteName: fallbackRouteName,
                color: Colors.white,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  eyebrow,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _FormSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AccessTypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _AccessTypeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Tipo de acceso',
        prefixIcon: Icon(Icons.door_front_door_outlined),
      ),
      items: const [
        DropdownMenuItem(value: 'publico', child: Text('Público')),
        DropdownMenuItem(value: 'privado', child: Text('Privado')),
        DropdownMenuItem(value: 'reserva', child: Text('Con reserva')),
        DropdownMenuItem(value: 'pagado', child: Text('Pagado')),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final AsyncValue<List<CategoryModel>> categories;
  final Set<int> selectedCategoryIds;
  final void Function(int id, bool selected) onToggle;
  final VoidCallback onRetry;

  const _CategorySelector({
    required this.categories,
    required this.selectedCategoryIds,
    required this.onToggle,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return categories.when(
      data: (items) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((category) {
          final selected = selectedCategoryIds.contains(category.id);
          return FilterChip(
            label: Text(category.name),
            selected: selected,
            onSelected: (value) => onToggle(category.id, value),
          );
        }).toList(),
      ),
      loading: () => const LinearProgressIndicator(minHeight: 3),
      error: (error, stackTrace) => _InlineFormError(
        message: 'No se pudieron cargar las categorías.',
        onRetry: onRetry,
      ),
    );
  }
}

class _InlineFormError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineFormError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _CoordinateFields extends StatelessWidget {
  final TextEditingController latController;
  final TextEditingController lonController;
  final String? Function(String?) validator;

  const _CoordinateFields({
    required this.latController,
    required this.lonController,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final fields = [
      TextFormField(
        controller: latController,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: const InputDecoration(
          labelText: 'Latitud',
          prefixIcon: Icon(Icons.north_rounded),
        ),
        validator: validator,
      ),
      TextFormField(
        controller: lonController,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: const InputDecoration(
          labelText: 'Longitud',
          prefixIcon: Icon(Icons.east_rounded),
        ),
        validator: validator,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [fields[0], const SizedBox(height: 14), fields[1]],
          );
        }
        return Row(
          children: [
            Expanded(child: fields[0]),
            const SizedBox(width: 12),
            Expanded(child: fields[1]),
          ],
        );
      },
    );
  }
}
