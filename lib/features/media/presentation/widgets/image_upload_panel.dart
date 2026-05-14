import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
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
        const SnackBar(
          content: Text('Imagen agregada. Gracias por mejorar este lugar.'),
        ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suma una foto real para que otros viajeros reconozcan mejor este lugar antes de visitarlo.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        if (_uploadedUrl != null) ...[
          _UploadedPreview(url: _uploadedUrl!),
          const SizedBox(height: 14),
        ],
        _UploadDropZone(isUploading: _isUploading, onTap: _pickAndUpload),
      ],
    );
  }
}

class _UploadedPreview extends StatelessWidget {
  final String url;

  const _UploadedPreview({required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Image.network(
            url,
            height: 190,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 120,
              width: double.infinity,
              alignment: Alignment.center,
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              child: const Icon(Icons.image_not_supported_outlined),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.deepForest.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.sun,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Foto agregada',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadDropZone extends StatelessWidget {
  final bool isUploading;
  final VoidCallback onTap;

  const _UploadDropZone({required this.isUploading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: isUploading ? null : onTap,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: isUploading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Icon(
                        Icons.add_photo_alternate_rounded,
                        color: theme.colorScheme.primary,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUploading ? 'Subiendo imagen...' : 'Agregar foto',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isUploading
                          ? 'Esto tomará solo un momento.'
                          : 'Elige una imagen desde tu galería.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
