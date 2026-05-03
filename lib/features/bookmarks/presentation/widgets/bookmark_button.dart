import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/api_exception.dart';
import '../../data/repositories/bookmark_repository.dart';

class BookmarkButton extends ConsumerStatefulWidget {
  final String poiId;
  final bool compact;

  const BookmarkButton({super.key, required this.poiId, this.compact = false});

  @override
  ConsumerState<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends ConsumerState<BookmarkButton> {
  bool _isToggling = false;

  Future<void> _toggle(bool isBookmarked) async {
    if (_isToggling) {
      return;
    }

    setState(() => _isToggling = true);
    try {
      final repository = ref.read(bookmarkRepositoryProvider);
      if (isBookmarked) {
        await repository.remove(widget.poiId);
      } else {
        await repository.add(widget.poiId);
      }

      ref.invalidate(bookmarkStatusProvider(widget.poiId));
      ref.invalidate(bookmarkedPoisProvider);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBookmarked
                ? 'POI eliminado de favoritos.'
                : 'POI guardado en favoritos.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'No se pudo actualizar favoritos.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isToggling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(bookmarkStatusProvider(widget.poiId));

    return status.when(
      data: (isBookmarked) {
        final icon = isBookmarked ? Icons.bookmark : Icons.bookmark_border;
        final label = isBookmarked ? 'Guardado' : 'Guardar';
        if (widget.compact) {
          return IconButton(
            onPressed: _isToggling ? null : () => _toggle(isBookmarked),
            icon: Icon(icon),
            tooltip: label,
          );
        }

        return OutlinedButton.icon(
          onPressed: _isToggling ? null : () => _toggle(isBookmarked),
          icon: _isToggling
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon),
          label: Text(label),
        );
      },
      loading: () => widget.compact
          ? const IconButton(onPressed: null, icon: Icon(Icons.bookmark_border))
          : OutlinedButton.icon(
              onPressed: null,
              icon: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              label: const Text('Cargando'),
            ),
      error: (error, stackTrace) => widget.compact
          ? IconButton(
              onPressed: () =>
                  ref.invalidate(bookmarkStatusProvider(widget.poiId)),
              icon: const Icon(Icons.bookmark_border),
              tooltip: 'Reintentar favorito',
            )
          : OutlinedButton.icon(
              onPressed: () =>
                  ref.invalidate(bookmarkStatusProvider(widget.poiId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar favorito'),
            ),
    );
  }
}
