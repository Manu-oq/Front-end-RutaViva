import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/custom_button.dart';
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
  String _accessType = 'public';
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
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            accessType: _accessType,
            imageUrl: _imageUrlController.text.trim(),
            contactPhone: _phoneController.text.trim(),
            contactEmail: _emailController.text.trim(),
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
      body: PoiFormBackground(
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
                            const PoiFormHero(
                              title: 'Comparte un lugar',
                              eyebrow: 'Nuevo aporte',
                              description:
                                  'Ayuda a otros viajeros a descubrir rincones, servicios o experiencias de La Araucanía.',
                              fallbackRouteName: AppRouteNames.profile,
                            ),
                            const SizedBox(height: 16),
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
                                      labelText: 'URL de imagen',
                                      prefixIcon: Icon(Icons.image_outlined),
                                    ),
                                    validator: _validateRequiredImageUrl,
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

  String? _validateRequiredImageUrl(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Ingresa una URL de imagen.';
    }
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme) {
      return 'Ingresa una URL de imagen válida.';
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
      error: (error, stackTrace) => InlineErrorWidget(
        message: 'No se pudieron cargar las categorías.',
        onRetry: onRetry,
      ),
    );
  }
}
