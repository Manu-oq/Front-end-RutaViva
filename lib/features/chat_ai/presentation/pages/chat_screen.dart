import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/safe_navigation.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/app_durations.dart';
import '../../../itinerary/presentation/providers/itinerary_provider.dart';
import '../../../map/domain/entities/map_point.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_header.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/trip_progress_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  bool _isNavigatingFromCandidate = false;
  bool _isOpeningCandidateMap = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(itineraryProvider.notifier).refreshCurrent(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppDurations.scroll,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);
    final itineraryState = ref.watch(itineraryProvider);
    final theme = Theme.of(context);
    final actionsLocked = chatNotifier.isInputLocked;
    final isMobile = AppResponsive.isMobile(context);

    ref.listen(chatProvider, (prev, next) {
      if (next.length > (prev?.length ?? 0)) {
        _scrollToBottom();
      }
    });

    final chatNotifier2 = ref.read(chatProvider.notifier);
    final hasSession = chatNotifier2.hasActiveSession;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppResponsive.maxContentWidth(context),
              ),
              child: Column(
                children: [
                  const ChatHeader(),
                  const TripProgressBar(),
                  if (itineraryState.current != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : 20,
                        0,
                        isMobile ? 16 : 20,
                        12,
                      ),
                      child: _LastItineraryBanner(
                        title: itineraryState.current!.title,
                        isLoading: itineraryState.isLoading,
                        onOpen: () => context.pushNamedSafe(
                          AppRouteNames.itineraryDetail,
                          pathParameters: {'id': itineraryState.current!.id},
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 20,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return ChatBubble(
                          message: msg.text,
                          isUser: msg.isUser,
                          isTyping: msg.isTyping,
                          evidenceLevel: msg.evidenceLevel,
                          actions: msg.actions,
                          itineraryCard: msg.itineraryCard,
                          candidatePois: msg.candidatePois,
                          selectedActionId: msg.selectedActionId,
                          actionsLocked: msg.actionsLocked,
                          disclaimerText: msg.disclaimerText,
                          onAction: actionsLocked
                              ? null
                              : (action) => _handleAction(context, ref, action),
                          onOpenItinerary: (id) => context.pushNamedSafe(
                            AppRouteNames.itineraryDetail,
                            pathParameters: {'id': id},
                          ),
                          onOpenPoi: (candidate) =>
                              _openCandidateDetail(context, candidate),
                          onShowPoiOnMap: (candidate) =>
                              _showCandidateOnMap(context, ref, candidate),
                          onUseCandidate: actionsLocked
                              ? null
                              : (candidate) => _useCandidate(ref, candidate),
                        );
                      },
                    ),
                  ),
                  if (hasSession && !chatNotifier.isGenerating)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 20,
                        vertical: 4,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: actionsLocked
                              ? null
                              : () async {
                                  final completed = await ref
                                      .read(chatProvider.notifier)
                                      .generateItinerary();
                                  if (completed && context.mounted) {
                                    final itinerary = ref
                                        .read(itineraryProvider)
                                        .current;
                                    if (itinerary != null) {
                                      context.pushNamedSafe(
                                        AppRouteNames.itineraryDetail,
                                        pathParameters: {'id': itinerary.id},
                                      );
                                    }
                                  }
                                },
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 20,
                          ),
                          label: const Text('Que lo arme Ara'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 14 : 20),
                    child: const ChatInputField(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCandidateDetail(
    BuildContext context,
    MessageCandidatePoi candidate,
  ) async {
    if (_isNavigatingFromCandidate || candidate.id.trim().isEmpty) {
      return;
    }
    _isNavigatingFromCandidate = true;
    try {
      await context.pushNamedSafe(
        AppRouteNames.poiDetail,
        pathParameters: {'id': candidate.id},
      );
    } finally {
      if (mounted) {
        _isNavigatingFromCandidate = false;
      }
    }
  }

  Future<void> _showCandidateOnMap(
    BuildContext context,
    WidgetRef ref,
    MessageCandidatePoi candidate,
  ) async {
    if (_isOpeningCandidateMap || !candidate.hasCoordinates) {
      return;
    }
    _isOpeningCandidateMap = true;
    ref
        .read(mapProvider.notifier)
        .showSinglePoi(
          MapPoint(
            id: candidate.id,
            name: candidate.name,
            description: candidate.description,
            categoryIds: candidate.categoryIds,
            coordinates: LatLng(candidate.latitude!, candidate.longitude!),
            imageUrl: candidate.imageUrl,
            distanceMeters: candidate.distanceMeters,
          ),
        );
    try {
      await context.pushNamedSafe(
        AppRouteNames.focusedMap,
        extra: AppRouteNames.chat,
      );
    } finally {
      if (mounted) {
        _isOpeningCandidateMap = false;
      }
    }
  }

  Future<void> _useCandidate(
    WidgetRef ref,
    MessageCandidatePoi candidate,
  ) async {
    final value = candidate.actionValue?.trim().isNotEmpty == true
        ? candidate.actionValue!.trim()
        : 'Quiero ir a ${candidate.name}';
    await ref
        .read(chatProvider.notifier)
        .sendMessage(value, visibleText: 'Quiero ir a ${candidate.name}');
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    MessageAction action,
  ) async {
    if (action.type == 'navigation') {
      final itineraryId = _readItineraryId(action.prompt);
      if (itineraryId != null) {
        context.pushNamedSafe(
          AppRouteNames.itineraryDetail,
          pathParameters: {'id': itineraryId},
        );
        return;
      }
    }
    final completed = await ref
        .read(chatProvider.notifier)
        .handleAction(action);
    if (!context.mounted) {
      return;
    }
    if (completed && action.isGenerate) {
      final itinerary = ref.read(itineraryProvider).current;
      if (itinerary != null) {
        context.pushNamedSafe(
          AppRouteNames.itineraryDetail,
          pathParameters: {'id': itinerary.id},
        );
      }
    }
  }

  String? _readItineraryId(String value) {
    final match = RegExp(
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    ).firstMatch(value);
    return match?.group(0);
  }
}

class _LastItineraryBanner extends StatelessWidget {
  final String title;
  final bool isLoading;
  final VoidCallback onOpen;

  const _LastItineraryBanner({
    required this.title,
    required this.isLoading,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        dense: true,
        leading: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.route_outlined, color: theme.colorScheme.primary),
        title: Text(
          isLoading ? 'Ara está generando una ruta...' : 'Última ruta generada',
          style: theme.textTheme.labelLarge,
        ),
        subtitle: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: TextButton(
          onPressed: isLoading ? null : onOpen,
          child: const Text('Ver'),
        ),
      ),
    );
  }
}
