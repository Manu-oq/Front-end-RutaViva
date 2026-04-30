import 'package:flutter/material.dart';

class PoiGalleryHeader extends StatelessWidget {
  final String? imageUrl;
  final String heroTag;

  const PoiGalleryHeader({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        background: hasImage
            ? Hero(
                tag: heroTag,
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const _PoiImagePlaceholder(),
                ),
              )
            : const _PoiImagePlaceholder(),
      ),
    );
  }
}

class _PoiImagePlaceholder extends StatelessWidget {
  const _PoiImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, size: 72, color: Colors.white70),
    );
  }
}
