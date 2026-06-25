import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/inline_error_widget.dart';
import '../../../../core/widgets/section_card.dart';
import 'package:latlong2/latlong.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../data/repositories/poi_repository.dart';
import '../providers/map_provider.dart';
import '../widgets/access_type_selector.dart';
import '../widgets/coordinate_fields.dart';
import '../widgets/location_picker_sheet.dart';
import '../widgets/poi_form_background.dart';
import '../widgets/poi_form_hero.dart';
import '../widgets/poi_image_upload_field.dart';

class CreatePoiPage extends ConsumerStatefulWidget {
  final String creationType;

  const CreatePoiPage({super.key, this.creationType = 'tourist'});

  @override
  ConsumerState<CreatePoiPage> createState() => _CreatePoiPageState();
}

class _CreatePoiPageState extends ConsumerState<CreatePoiPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  late final TextEditingController _latController;
  late final TextEditingController _lonController;
  String _accessType = 'public';
  String? _uploadedImageUrl;
  final Set<int> _selectedCategoryIds = {};
  bool _isSubmitting = false;
  String? _formErrorMessage;

  bool get _isEntrepreneurCreation => widget.creationType == 'entrepreneur';

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
    final latitude = double.tryParse(_latController.text.trim());
    final longitude = double.tryParse(_lonController.text.trim());
    if (latitude == null || longitude == null) {
      setState(() {
        _formErrorMessage =
            'Revisa la ubicación: latitud y longitud deben ser números válidos.';
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
          .createPoi(
            creationType: _isEntrepreneurCreation ? 'entrepreneur' : 'tourist',
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            accessType: _accessType,
            imageUrl: _uploadedImageUrl?.trim(),
            contactPhone: _emptyToNull(_normalizedPhone(_phoneController.text)),
            contactEmail: _emptyToNull(_emailController.text.trim()),
            categoryIds: _selectedCategoryIds.toList()..sort(),
            latitude: latitude,
            longitude: longitude,
          );

      await ref
          .read(mapProvider.notifier)
          .loadNearby(center: poi.toMapPoint().coordinates);
      ref.invalidate(myPoisProvider);
      ref.invalidate(entrepreneurPoisProvider);

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
      setState(() => _formErrorMessage = message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final isMobile = AppResponsive.isMobile(context);
    final isEntrepreneurCreation = _isEntrepreneurCreation;

    return Scaffold(
      body: PoiFormBackground(
        child: SafeArea(
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                              title: isEntrepreneurCreation
                                  ? 'Publica tu negocio'
                                  : 'Comparte un lugar',
                              eyebrow: isEntrepreneurCreation
                                  ? 'Nuevo lugar emprendedor'
                                  : 'Nuevo aporte',
                              description: isEntrepreneurCreation
                                  ? 'Suma tu negocio, servicio o experiencia turística al mapa de Ruta Viva.'
                                  : 'Ayuda a otros viajeros a descubrir rincones, servicios o experiencias de La Araucanía.',
                              fallbackRouteName: isEntrepreneurCreation
                                  ? AppRouteNames.entrepreneur
                                  : AppRouteNames.profile,
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
                              child: _CategorySelector(
                                categories: categories,
                                selectedCategoryIds: _selectedCategoryIds,
                                onToggle: _toggleCategory,
                                onRetry: () =>
                                    ref.invalidate(categoriesProvider),
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
                              title: isEntrepreneurCreation
                                  ? 'Contacto del negocio'
                                  : 'Contacto',
                              icon: Icons.contact_phone_rounded,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: isEntrepreneurCreation
                                          ? 'Teléfono público obligatorio'
                                          : 'Teléfono público opcional',
                                      hintText: '+56912345678',
                                      prefixIcon: const Icon(
                                        Icons.phone_outlined,
                                      ),
                                    ),
                                    validator: _phoneValidator,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText: isEntrepreneurCreation
                                          ? 'Email público obligatorio'
                                          : 'Email público opcional',
                                      hintText: 'contacto@ejemplo.cl',
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                      ),
                                    ),
                                    validator: _emailValidator,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SectionCard(
                              title: 'Foto del lugar',
                              icon: Icons.add_photo_alternate_rounded,
                              child: PoiImageUploadField(
                                imageUrl: _uploadedImageUrl,
                                enabled: !_isSubmitting,
                                onChanged: (url) =>
                                    setState(() => _uploadedImageUrl = url),
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
    if (selected &&
        !_selectedCategoryIds.contains(id) &&
        _selectedCategoryIds.length >= 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Máximo 3 categorías')));
      return;
    }
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
    // Coordinate fields are hidden; submit handles parse errors with a visible
    // form banner instead of an offstage field error.
    return null;
  }

  String? _phoneValidator(String? value) {
    final text = _normalizedPhone(value ?? '');
    if (text.isEmpty) {
      return _isEntrepreneurCreation ? 'Ingresa un teléfono público.' : null;
    }
    final isValid = RegExp(r'^\+56\d{9,11}$').hasMatch(text);
    if (!isValid) {
      return 'Usa formato chileno: +56 seguido de 9 a 11 dígitos.';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return _isEntrepreneurCreation ? 'Ingresa un email público.' : null;
    }
    final isValid = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(text);
    if (!isValid) {
      return 'Ingresa un email válido.';
    }
    return null;
  }

  String _normalizedPhone(String value) {
    return value.trim().replaceAll(RegExp(r'[\s-]'), '');
  }

  String? _emptyToNull(String value) {
    return value.isEmpty ? null : value;
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
      data: (items) {
        final topLevel = items.topLevelAttractionCategories();

        final grouped = <({CategoryModel parent, List<CategoryModel> children})>[];
        final standalone = <CategoryModel>[];

        for (final category in topLevel) {
          final children = items.childrenOf(category.id);
          if (children.isNotEmpty) {
            grouped.add((parent: category, children: children));
          } else {
            standalone.add(category);
          }
        }

        if (grouped.isEmpty && standalone.isEmpty) {
          return const Text('No hay categorías disponibles.');
        }

        final children = <Widget>[];

        for (final group in grouped) {
          children.add(_GroupHeader(text: group.parent.name));
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: group.children.map((child) {
                  final selected = selectedCategoryIds.contains(child.id);
                  return FilterChip(
                    label: Text(
                      child.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: selected,
                    onSelected: (value) => onToggle(child.id, value),
                  );
                }).toList(),
              ),
            ),
          );
        }

        if (standalone.isNotEmpty) {
          children.add(const _GroupHeader(text: 'Otros'));
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: standalone.map((category) {
                  final selected = selectedCategoryIds.contains(category.id);
                  return FilterChip(
                    label: Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: selected,
                    onSelected: (value) => onToggle(category.id, value),
                  );
                }).toList(),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      },
      loading: () => const LinearProgressIndicator(minHeight: 3),
      error: (error, stackTrace) => InlineErrorWidget(
        message: 'No se pudieron cargar las categorías.',
        onRetry: onRetry,
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String text;

  const _GroupHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Divider(endIndent: 12, color: theme.colorScheme.outlineVariant),
          ),
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Divider(indent: 12, color: theme.colorScheme.outlineVariant),
          ),
        ],
      ),
    );
  }
}
