import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/inline_error_widget.dart';
import '../../../map/data/repositories/poi_repository.dart';
import '../../data/models/entrepreneur_models.dart';
import '../../data/repositories/entrepreneur_repository.dart';

class PoiPostsManagementPage extends ConsumerWidget {
  final String poiId;

  const PoiPostsManagementPage({super.key, required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poiAsync = ref.watch(poiModelDetailProvider(poiId));

    return poiAsync.when(
      data: (poi) => _PoiPostsBody(poiId: poiId, poiName: poi.name),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: SafeArea(
          child: Center(
            child: FilledButton.icon(
              onPressed: () => ref.invalidate(poiModelDetailProvider(poiId)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ),
        ),
      ),
    );
  }
}

class _PoiPostsBody extends ConsumerStatefulWidget {
  final String poiId;
  final String poiName;

  const _PoiPostsBody({required this.poiId, required this.poiName});

  @override
  ConsumerState<_PoiPostsBody> createState() => _PoiPostsBodyState();
}

class _PoiPostsBodyState extends ConsumerState<_PoiPostsBody> {
  static const maxPosts = 6;
  List<EntrepreneurPostModel>? _optimisticPosts;
  List<EntrepreneurPostModel> _lastRenderedPosts = const [];
  bool _isReordering = false;

  Future<void> _openPostDialog({EntrepreneurPostModel? post}) async {
    final titleController = TextEditingController(text: post?.title ?? '');
    final contentController = TextEditingController(text: post?.content ?? '');
    final isPublished = post?.isPublished ?? true;
    final isPinned = post?.isPinned ?? false;
    final saved = await showDialog<_PostDraft>(
      context: context,
      builder: (ctx) => _PostEditDialog2(
        titleController: titleController,
        contentController: contentController,
        initialPublished: isPublished,
        initialPinned: isPinned,
        isEditing: post != null,
      ),
    );
    if (saved == null) return;
    try {
      final repo = ref.read(entrepreneurRepositoryProvider);
      if (post == null) {
        await repo.createPoiPost(
          poiId: widget.poiId,
          title: saved.title,
          content: saved.content,
          isPublished: saved.isPublished,
        );
      } else {
        await repo.updatePoiPost(
          poiId: widget.poiId,
          postId: post.id,
          title: saved.title,
          content: saved.content,
          isPublished: saved.isPublished,
        );
        if (saved.isPinned != post.isPinned) {
          await repo.pinPoiPost(
            poiId: widget.poiId,
            postId: post.id,
            pinned: saved.isPinned,
          );
        }
      }
      ref.invalidate(poiPostsProvider(widget.poiId));
      ref.invalidate(poiPublicPostsProvider(widget.poiId));
      if (!mounted) return;
      setState(() => _optimisticPosts = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post guardado.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos guardar el post.')),
      );
    }
  }

  Future<void> _deletePost(EntrepreneurPostModel post) async {
    try {
      await ref
          .read(entrepreneurRepositoryProvider)
          .deletePoiPost(poiId: widget.poiId, postId: post.id);
      ref.invalidate(poiPostsProvider(widget.poiId));
      ref.invalidate(poiPublicPostsProvider(widget.poiId));
      if (!mounted) return;
      setState(() => _optimisticPosts = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post eliminado.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos eliminar el post.')),
      );
    }
  }

  Future<void> _togglePin(EntrepreneurPostModel post) async {
    try {
      await ref
          .read(entrepreneurRepositoryProvider)
          .pinPoiPost(
            poiId: widget.poiId,
            postId: post.id,
            pinned: !post.isPinned,
          );
      ref.invalidate(poiPostsProvider(widget.poiId));
      ref.invalidate(poiPublicPostsProvider(widget.poiId));
      if (!mounted) return;
      setState(() => _optimisticPosts = null);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos actualizar el post.')),
      );
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    final items = _lastRenderedPosts;
    if (_isReordering || items.length <= 1) return;

    final actualNew = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final reordered = [...items];
    final item = reordered.removeAt(oldIndex);
    reordered.insert(actualNew, item);

    setState(() {
      _optimisticPosts = reordered;
      _isReordering = true;
    });

    unawaited(_persistReorder(reordered, previous: items));
  }

  Future<void> _persistReorder(
    List<EntrepreneurPostModel> reordered, {
    required List<EntrepreneurPostModel> previous,
  }) async {
    final payload = EntrepreneurRepository.buildPostReorderPayload(reordered);
    debugPrint('[POI posts] Reordering ${widget.poiId}: $payload');
    try {
      await ref
          .read(entrepreneurRepositoryProvider)
          .reorderPoiPosts(poiId: widget.poiId, posts: payload);
      ref.invalidate(poiPublicPostsProvider(widget.poiId));
      final refreshed = await ref.refresh(
        poiPostsProvider(widget.poiId).future,
      );
      if (!mounted) return;
      setState(() {
        _optimisticPosts = refreshed;
        _isReordering = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orden de posts actualizado.')),
      );
    } catch (error) {
      debugPrint('[POI posts] Reorder failed for ${widget.poiId}: $error');
      if (!mounted) return;
      setState(() {
        _optimisticPosts = previous;
        _isReordering = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos actualizar el orden.')),
      );
    }
  }

  List<EntrepreneurPostModel> _displayItems(List<EntrepreneurPostModel> items) {
    final displayItems = _optimisticPosts ?? items;
    _lastRenderedPosts = displayItems;
    return displayItems;
  }

  Widget _reorderStatus(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Guardando nuevo orden...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posts = ref.watch(poiPostsProvider(widget.poiId));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(poiPostsProvider(widget.poiId));
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.deepForest,
              foregroundColor: Colors.white,
              leading: const AppBackButton(
                fallbackRouteName: AppRouteNames.entrepreneur,
                color: Colors.white,
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(72, 0, 20, 12),
                title: Text(
                  widget.poiName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                background: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.deepForest,
                        AppColors.forest,
                        AppColors.moss,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
                    child: posts.when(
                      data: (items) {
                        final displayItems = _displayItems(items);
                        final canAdd = displayItems.length < maxPosts;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Posts del lugar',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        canAdd
                                            ? '${displayItems.length} de $maxPosts publicaciones'
                                            : 'Límite de $maxPosts publicaciones alcanzado',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                if (canAdd)
                                  FilledButton.icon(
                                    onPressed: _openPostDialog,
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Nuevo post'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_isReordering) _reorderStatus(context),
                            if (displayItems.isEmpty)
                              const EmptyStateWidget(
                                icon: Icons.campaign_outlined,
                                message:
                                    'Aún no creaste posts para este lugar.',
                              )
                            else
                              ReorderableListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayItems.length,
                                onReorder: _onReorder,
                                buildDefaultDragHandles: false,
                                proxyDecorator: (child, index, anim) =>
                                    _ProxyDecorator(
                                      animation: anim,
                                      child: child,
                                    ),
                                itemBuilder: (context, index) {
                                  final post = displayItems[index];
                                  return _PostItem(
                                    key: ValueKey(post.id),
                                    index: index,
                                    post: post,
                                    onEdit: () => _openPostDialog(post: post),
                                    onDelete: () => _deletePost(post),
                                    onTogglePin: () => _togglePin(post),
                                    isLast: index == displayItems.length - 1,
                                  );
                                },
                              ),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => InlineErrorWidget(
                        message:
                            'No se pudieron cargar los posts de este lugar.',
                        onRetry: () =>
                            ref.invalidate(poiPostsProvider(widget.poiId)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostItem extends StatelessWidget {
  final int index;
  final EntrepreneurPostModel post;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;
  final bool isLast;

  const _PostItem({
    super.key,
    required this.index,
    required this.post,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePin,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: post.isPinned
            ? AppColors.sun.withValues(alpha: 0.12)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: post.isPinned
              ? AppColors.sun.withValues(alpha: 0.28)
              : theme.colorScheme.outlineVariant,
          width: post.isPinned ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              _PostOrderBadge(index: index + 1),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  post.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!post.isPublished)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Oculto',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(
                    value: 'pin',
                    child: Text(post.isPinned ? 'Desfijar' : 'Fijar'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      onEdit();
                    case 'pin':
                      onTogglePin();
                    case 'delete':
                      onDelete();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ProxyDecorator extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const _ProxyDecorator({required this.child, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = Curves.easeInOut.transform(animation.value);
        return Transform.scale(
          scale: 1.0 + (value * 0.06),
          child: Material(
            elevation: 4,
            shadowColor: Theme.of(
              context,
            ).colorScheme.shadow.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(22),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _PostOrderBadge extends StatelessWidget {
  final int index;

  const _PostOrderBadge({required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$index',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PostDraft {
  final String title;
  final String content;
  final bool isPublished;
  final bool isPinned;

  const _PostDraft({
    required this.title,
    required this.content,
    this.isPublished = true,
    this.isPinned = false,
  });
}

class _PostEditDialog2 extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final bool initialPublished;
  final bool initialPinned;
  final bool isEditing;

  const _PostEditDialog2({
    required this.titleController,
    required this.contentController,
    required this.initialPublished,
    required this.initialPinned,
    required this.isEditing,
  });

  @override
  State<_PostEditDialog2> createState() => _PostEditDialog2State();
}

class _PostEditDialog2State extends State<_PostEditDialog2> {
  late bool _isPublished;
  late bool _isPinned;

  @override
  void initState() {
    super.initState();
    _isPublished = widget.initialPublished;
    _isPinned = widget.initialPinned;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Editar post' : 'Nuevo post'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widget.titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: widget.contentController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Contenido'),
            ),
            if (widget.isEditing) ...[
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Publicado'),
                value: _isPublished,
                onChanged: (v) => setState(() => _isPublished = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fijado'),
                subtitle: const Text('Aparece primero en el feed'),
                value: _isPinned,
                onChanged: (v) => setState(() => _isPinned = v),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final title = widget.titleController.text.trim();
            final content = widget.contentController.text.trim();
            if (title.isEmpty) return;
            Navigator.of(context).pop(
              _PostDraft(
                title: title,
                content: content,
                isPublished: _isPublished,
                isPinned: _isPinned,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
