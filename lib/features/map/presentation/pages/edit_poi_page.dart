import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/inline_error_widget.dart';
import '../../../../core/widgets/section_card.dart';
import 'package:latlong2/latlong.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../data/models/poi_model.dart';
import '../../data/repositories/poi_repository.dart';
import '../providers/map_provider.dart';
import '../widgets/access_type_selector.dart';
import '../widgets/coordinate_fields.dart';
import '../widgets/location_picker_sheet.dart';
import '../widgets/poi_form_background.dart';
import '../widgets/poi_form_hero.dart';

class EditPoiPage extends ConsumerWidget {
  final String poiId;

  const EditPoiPage({super.key, required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poi = ref.watch(poiModelDetailProvider(poiId));
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      body: PoiFormBackground(
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
  String? _formErrorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.poi.name);
    _descriptionController = TextEditingController(
      text: widget.poi.description,
    );
    _phoneController = TextEditingController(
      text: widget.poi.contactPhone ?? '',
    );
    _emailController = TextEditingController(
      text: widget.poi.contactEmail ?? '',
    );
    _latController = TextEditingController(
      text: widget.poi.latitude.toStringAsFixed(6),
    );
    _lonController = TextEditingController(
      text: widget.poi.longitude.toStringAsFixed(6),
    );
    _accessType = _normalizeAccessType(widget.poi.accessType);
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
      setState(() {
        _formErrorMessage = 'Selecciona al menos una categoría.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _formErrorMessage = null;
    });
    try {
      final poi = await ref
          .read(poiRepositoryProvider)
          .updatePoi(
            poiId: widget.poi.id,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            accessType: _accessType,
            contactPhone: _phoneController.text.trim(),
            contactEmail: _emailController.text.trim(),
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
      setState(() => _formErrorMessage = message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppResponsive.maxContentWidth(context),
              ),
              child: Padding(
                padding: AppResponsive.value<EdgeInsets>(
                  context,
                  mobile: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                  tablet: const EdgeInsets.fromLTRB(20, 18, 20, 112),
                  desktop: const EdgeInsets.fromLTRB(20, 18, 20, 112),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PoiFormHero(
                        title: 'Editar lugar',
                        eyebrow: 'Ficha pública',
                        description:
                            'Mantén la información clara, actualizada y útil para quienes visiten este lugar.',
                        fallbackRouteName: AppRouteNames.poiDetail,
                        fallbackPathParameters: {'id': widget.poi.id},
                      ),
                      SizedBox(height: isMobile ? 14 : 16),
                      if (_formErrorMessage != null) ...[
                        ErrorBanner(
                          message: _formErrorMessage!,
                          onDismiss: () =>
                              setState(() => _formErrorMessage = null),
                        ),
                        SizedBox(height: isMobile ? 14 : 16),
                      ],
                      SectionCard(
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
                            AccessTypeSelector(
                              value: _accessType,
                              onChanged: (value) =>
                                  setState(() => _accessType = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'Categorías',
                        icon: Icons.local_offer_rounded,
                        child: _CategoryList(
                          categories: widget.categories,
                          selectedCategoryIds: _selectedCategoryIds,
                          onToggle: _toggleCategory,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'Ubicación',
                        icon: Icons.my_location_rounded,
                        child: CoordinateFields(
                          latController: _latController,
                          lonController: _lonController,
                          validator: _coordinateValidator,
                          onPick: _pickLocation,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
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

  String _normalizeAccessType(String value) {
    return switch (value) {
      'public' || 'restricted' || 'private' => value,
      _ => 'public',
    };
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
        constraints: BoxConstraints(
          maxWidth: AppResponsive.value<double>(
            context,
            mobile: double.infinity,
            tablet: 520,
            desktop: 560,
          ),
        ),
        child: Padding(
          padding: AppResponsive.pagePadding(context),
          child: Container(
            padding: EdgeInsets.all(AppResponsive.cardPadding(context)),
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
                InlineErrorWidget(message: message, onRetry: onRetry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
