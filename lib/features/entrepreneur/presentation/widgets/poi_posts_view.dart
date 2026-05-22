import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/authenticated_network_image.dart';
import '../../../../core/widgets/section_card.dart';
import '../../data/models/entrepreneur_models.dart';
import '../../data/repositories/entrepreneur_repository.dart';

final poiPublicPostsProvider =
    FutureProvider.family<List<EntrepreneurPostModel>, String>((
      ref,
      poiId,
    ) async {
      return ref.watch(entrepreneurRepositoryProvider).getPublicPoiPosts(poiId);
    });

class PoiPostsView extends ConsumerWidget {
  final String poiId;

  const PoiPostsView({super.key, required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(poiPublicPostsProvider(poiId));

    return posts.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return SectionCard(
          title: 'Novedades del lugar',
          icon: Icons.campaign_rounded,
          child: Column(
            children: items.map((post) => _PoiPostCard(post: post)).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _PoiPostCard extends StatelessWidget {
  final EntrepreneurPostModel post;

  const _PoiPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = ApiConstants.resolveBackendUrl(post.imageUrl);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (post.isPinned)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.push_pin_rounded,
                    color: AppColors.sun,
                    size: 16,
                  ),
                ),
              Expanded(
                child: Text(
                  post.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AuthenticatedNetworkImage(
                imageUrl: imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            post.content,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
