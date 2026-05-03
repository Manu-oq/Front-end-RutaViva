import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/error/api_exception.dart';
import '../../../map/data/repositories/poi_repository.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../../data/repositories/media_repository.dart';

class ImageUploadPanel extends ConsumerStatefulWidget {
  final String poiId;

  const ImageUploadPanel({super.key, required this.poiId});

  @override
  ConsumerState<ImageUploadPanel> createState() => _ImageUploadPanelState();
}

class _ImageUploadPanelState extends ConsumerState<ImageUploadPanel> {
  final _picker = ImagePicker();
  bool _isUploading = false;
  String? _uploadedUrl;

  Future<void> _pickAndUpload() async {
    if (_isUploading) {
      return;
    }

    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile == null) {
      return;
    }

    setState(() => _isUploading = true);
    try {
      final bytes = await pickedFile.readAsBytes();
      final url = await ref
          .read(mediaRepositoryProvider)
          .uploadImage(bytes: bytes, filename: pickedFile.name);
      final updatedPoi = await ref
          .read(poiRepositoryProvider)
          .appendImage(poiId: widget.poiId, imageUrl: url);

      ref.invalidate(poiDetailProvider(widget.poiId));
      final mapState = ref.read(mapProvider);
      await ref.read(mapProvider.notifier).loadNearby(center: mapState.center);

      if (!mounted) {
        return;
      }
      setState(() => _uploadedUrl = updatedPoi.toMapPoint().imageUrl ?? url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen subida y asociada al POI.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'No se pudo subir la imagen.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.25,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Imágenes del lugar',
            style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Sube una imagen al backend local y guárdala en multimedia_urls del POI.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (_uploadedUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                _uploadedUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 80,
                  alignment: Alignment.center,
                  color: Colors.black12,
                  child: Text(_uploadedUrl!, textAlign: TextAlign.center),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickAndUpload,
            icon: _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: Text(_isUploading ? 'Subiendo...' : 'Subir imagen'),
          ),
        ],
      ),
    );
  }
}
