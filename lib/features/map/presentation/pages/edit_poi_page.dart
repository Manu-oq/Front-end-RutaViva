import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/custom_button.dart';
import 'package:latlong2/latlong.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../data/models/poi_model.dart';
import '../../data/repositories/poi_repository.dart';
import '../providers/map_provider.dart';
import '../widgets/location_picker_sheet.dart';

class EditPoiPage extends ConsumerWidget {
  final String poiId;

  const EditPoiPage({super.key, required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poi = ref.watch(poiModelDetailProvider(poiId));
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      body: _PoiFormBackground(
        child: SafeArea(
          child: poi.when(
            data: (poi) => categories.when(
              data: (categories) => _EditPoiForm(
                key: ValueKey(poi.id),
                poi: poi,
                categories: categories,
              ),
              loading: () => const _CenteredProgress(),
              error: (error, stackTrace) => _EditPoiError(
                message: 'No se pudieron cargar las categorías.',
                onRetry: () => ref.invalidate(categoriesProvider),
                fallbackPoiId: poiId,
              ),
            ),
            loading: () => const _CenteredProgress(),
            error: (error, stackTrace) => _EditPoiError(
              message: 'No se pudo cargar este lugar.',
              onRetry: () => ref.invalidate(poiModelDetailProvider(poiId)),
              fallbackPoiId: poiId,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditPoiForm extends ConsumerStatefulWidget {
  final PoiModel poi;
  final List<CategoryModel> categories;

  const _EditPoiForm({super.key, required this.poi, required this.categories});

  @override
  ConsumerState<_EditPoiForm> createState() => _EditPoiFormState();
}

class _EditPoiFormState extends ConsumerState<_EditPoiForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _latController;
  late final TextEditingController _lonController;
  late String _accessType;
  late final Set<int> _selectedCategoryIds;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.poi.nombre);
    _descriptionController = TextEditingController(
      text: widget.poi.descripcion,
    );
    _phoneController = TextEditingController(
      text: widget.poi.telefonoPublico ?? '',
    );
    _emailController = TextEditingController(
      text: widget.poi.emailPublico ?? '',
    );
    _latController = TextEditingController(
      text: widget.poi.latitude.toStringAsFixed(6),
    );
    _lonController = TextEditingController(
      text: widget.poi.longitude.toStringAsFixed(6),
    );
    _accessType = widget.poi.tipoAcceso;
    _selectedCategoryIds = {...widget.poi.categoryIds};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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
          .updatePoi(
            poiId: widget.poi.id,
            nombre: _nameController.text.trim(),
            descripcion: _descriptionController.text.trim(),
            tipoAcceso: _accessType,
            telefonoPublico: _phoneController.text.trim(),
            emailPublico: _emailController.text.trim(),
            categoryIds: _selectedCategoryIds.toList()..sort(),
            latitude: double.parse(_latController.text.trim()),
            longitude: double.parse(_lonController.text.trim()),
          );

      ref.invalidate(myPoisProvider);
      ref.invalidate(poiModelDetailProvider(widget.poi.id));
      ref.invalidate(poiDetailProvider(widget.poi.id));
      await ref
          .read(mapProvider.notifier)
          .loadNearby(center: poi.toMapPoint().coordinates);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lugar actualizado correctamente.')),
      );
      context.goNamed(AppRouteNames.poiDetail, pathParameters: {'id': poi.id});
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'No se pudo actualizar el lugar.';
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
    return CustomScrollView(
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
                      _FormHero(
                        title: 'Editar lugar',
                        eyebrow: 'Ficha pública',
                        description:
                            'Mantén la información clara, actualizada y útil para quienes visiten este lugar.',
                        fallbackRouteName: AppRouteNames.poiDetail,
                        fallbackPathParameters: {'id': widget.poi.id},
                      ),
                      const SizedBox(height: 16),
                      _FormSection(
                        title: 'Información principal',
                        icon: Icons.place_rounded,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
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
                                    'Actualiza qué lo hace especial, cómo llegar o qué deberían saber los visitantes.',
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
                        child: _CategoryList(
                          categories: widget.categories,
                          selectedCategoryIds: _selectedCategoryIds,
                          onToggle: _toggleCategory,
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
                          onPick: _pickLocation,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FormSection(
                        title: 'Contacto',
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      CustomButton(
                        text: 'Guardar cambios',
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
    );
  }

  Future<void> _pickLocation() async {
    final current = LatLng(
      double.tryParse(_latController.text.trim()) ??
          araucaniaDefaultCenter.latitude,
      double.tryParse(_lonController.text.trim()) ??
          araucaniaDefaultCenter.longitude,
    );
    final picked = await showLocationPickerSheet(
      context,
      initialLocation: current,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _latController.text = picked.coordinates.latitude.toStringAsFixed(6);
      _lonController.text = picked.coordinates.longitude.toStringAsFixed(6);
    });
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

class _CategoryList extends StatelessWidget {
  final List<CategoryModel> categories;
  final Set<int> selectedCategoryIds;
  final void Function(int id, bool selected) onToggle;

  const _CategoryList({
    required this.categories,
    required this.selectedCategoryIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final selected = selectedCategoryIds.contains(category.id);
        return FilterChip(
          label: Text(category.name),
          selected: selected,
          onSelected: (value) => onToggle(category.id, value),
        );
      }).toList(),
    );
  }
}

class _CenteredProgress extends StatelessWidget {
  const _CenteredProgress();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _EditPoiError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String fallbackPoiId;

  const _EditPoiError({
    required this.message,
    required this.onRetry,
    required this.fallbackPoiId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: AppColors.ambientShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBackButton(
                  fallbackRouteName: AppRouteNames.poiDetail,
                  fallbackPathParameters: {'id': fallbackPoiId},
                ),
                const SizedBox(height: 12),
                Icon(
                  Icons.info_outline_rounded,
                  size: 44,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Intenta nuevamente para seguir editando la información del lugar.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PoiFormBackground extends StatelessWidget {
  final Widget child;

  const _PoiFormBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
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
                : AppColors.mint.withValues(alpha: 0.42),
            isDark
                ? theme.colorScheme.surfaceContainerLowest
                : theme.colorScheme.surface,
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
  final Map<String, String> fallbackPathParameters;

  const _FormHero({
    required this.title,
    required this.eyebrow,
    required this.description,
    required this.fallbackRouteName,
    this.fallbackPathParameters = const {},
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
                fallbackPathParameters: fallbackPathParameters,
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

class _CoordinateFields extends StatelessWidget {
  final TextEditingController latController;
  final TextEditingController lonController;
  final String? Function(String?) validator;
  final VoidCallback onPick;

  const _CoordinateFields({
    required this.latController,
    required this.lonController,
    required this.validator,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.location_pin, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${latController.text}, ${lonController.text}',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onPick,
                icon: const Icon(Icons.map_rounded),
                label: const Text('Elegir en mapa'),
              ),
            ],
          ),
        ),
        Offstage(
          child: Column(
            children: [
              TextFormField(controller: latController, validator: validator),
              TextFormField(controller: lonController, validator: validator),
            ],
          ),
        ),
      ],
    );
  }
}
