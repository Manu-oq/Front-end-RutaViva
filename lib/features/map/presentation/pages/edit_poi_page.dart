import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../data/models/poi_model.dart';
import '../../data/repositories/poi_repository.dart';
import '../providers/map_provider.dart';

class EditPoiPage extends ConsumerWidget {
  final String poiId;

  const EditPoiPage({super.key, required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poi = ref.watch(poiModelDetailProvider(poiId));
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar POI')),
      body: poi.when(
        data: (poi) => categories.when(
          data: (categories) => _EditPoiForm(
            key: ValueKey(poi.id),
            poi: poi,
            categories: categories,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _EditPoiError(
            message: 'No se pudieron cargar categorías: $error',
            onRetry: () => ref.invalidate(categoriesProvider),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _EditPoiError(
          message: 'No se pudo cargar este POI: $error',
          onRetry: () => ref.invalidate(poiModelDetailProvider(poiId)),
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
        const SnackBar(content: Text('POI actualizado correctamente.')),
      );
      context.goNamed(AppRouteNames.poiDetail, pathParameters: {'id': poi.id});
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'No se pudo actualizar el POI.';
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
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.poi.nombre, style: theme.textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Edita la ficha pública del punto de interés. El backend recalcula embedding si cambia nombre o descripción.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value ?? '').trim().length < 3) {
                  return 'Ingresa un nombre válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value ?? '').trim().length < 20) {
                  return 'La descripción debe tener al menos 20 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _accessType,
              decoration: const InputDecoration(
                labelText: 'Tipo de acceso',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'publico', child: Text('Público')),
                DropdownMenuItem(value: 'privado', child: Text('Privado')),
                DropdownMenuItem(value: 'reserva', child: Text('Con reserva')),
                DropdownMenuItem(value: 'pagado', child: Text('Pagado')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _accessType = value);
                }
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Categorías',
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.categories.map((category) {
                final selected = _selectedCategoryIds.contains(category.id);
                return FilterChip(
                  label: Text(category.name),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedCategoryIds.add(category.id);
                      } else {
                        _selectedCategoryIds.remove(category.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Latitud',
                      border: OutlineInputBorder(),
                    ),
                    validator: _coordinateValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lonController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Longitud',
                      border: OutlineInputBorder(),
                    ),
                    validator: _coordinateValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono público opcional',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email público opcional',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: 'Guardar POI',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  String? _coordinateValidator(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null) {
      return 'Coordenada inválida.';
    }
    return null;
  }
}

class _EditPoiError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _EditPoiError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
