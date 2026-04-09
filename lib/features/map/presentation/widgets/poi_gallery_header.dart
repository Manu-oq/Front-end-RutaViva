import 'package:flutter/material.dart';

class PoiGalleryHeader extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const PoiGalleryHeader({super.key, required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: heroTag,
          child: Image.network(imageUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }
}