import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/authenticated_network_image.dart';
import '../../../media/data/repositories/media_repository.dart';

class PoiImageUploadField extends ConsumerStatefulWidget {
  final String? imageUrl;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const PoiImageUploadField({
    super.key,
    required this.imageUrl,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  ConsumerState<PoiImageUploadField> createState() =>
      _PoiImageUploadFieldState();
}

class _PoiImageUploadFieldState extends ConsumerState<PoiImageUploadField> {
  static const int _maxBytes = 5 * 1024 * 1024;
  static final RegExp _allowedImageExtension = RegExp(
    r'\.(jpe?g|png)$',
    caseSensitive: false,
  );

  final _picker = ImagePicker();
  bool _isUploading = false;
  String? _errorMessage;

  Future<void> _pickAndUpload(ImageSource source) async {
    if (_isUploading || !widget.enabled) {
      return;
    }

    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 88,
    );
    if (pickedFile == null) {
      return;
    }

    final fileName = pickedFile.name;
    if (!_allowedImageExtension.hasMatch(fileName)) {
      setState(() {
        _errorMessage = 'Selecciona una imagen JPG o PNG.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final bytes = await pickedFile.readAsBytes();
      if (bytes.length > _maxBytes) {
        throw const ApiException(message: 'La imagen debe pesar máximo 5 MB.');
      }

      final url = await ref
          .read(mediaRepositoryProvider)
          .uploadImage(bytes: bytes, filename: fileName);

      if (!mounted) {
        return;
      }
      widget.onChanged(url);
      setState(() => _errorMessage = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen subida correctamente.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error is ApiException
            ? error.message
            : 'No se pudo subir la imagen.';
      });
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _removeImage() {
    widget.onChanged(null);
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = widget.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sube una foto real del lugar. Aceptamos JPG o PNG de hasta 5 MB.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        if (hasImage) ...[
          _ImagePreview(imageUrl: imageUrl, onRemove: _removeImage),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploading || !widget.enabled
                    ? null
                    : () => _pickAndUpload(ImageSource.gallery),
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library_outlined),
                label: Text(_isUploading ? 'Subiendo...' : 'Subir imagen'),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'Abrir cámara',
              onPressed: _isUploading || !widget.enabled
                  ? null
                  : () => _pickAndUpload(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
            ),
          ],
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onRemove;

  const _ImagePreview({required this.imageUrl, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          AuthenticatedNetworkImage(
            imageUrl: imageUrl,
            height: 190,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context) => Container(
              height: 190,
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
                    'Foto lista',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: IconButton.filledTonal(
              tooltip: 'Quitar imagen',
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
