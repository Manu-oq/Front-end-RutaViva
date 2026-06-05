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
  bool _isOpeningItinerary = false;

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
    final waitingForFirstStreamEvent = ref.watch(
      chatWaitingForFirstStreamEventProvider,
    );
    final theme = Theme.of(context);
    final actionsLocked = chatNotifier.isInputLocked;
    final isMobile = AppResponsive.isMobile(context);

    ref.listen(chatProvider, (prev, next) {
      if (next.length > (prev?.length ?? 0)) {
        _scrollToBottom();
      }
    });

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
                        onOpen: () => _openItineraryDetail(
                          context,
                          itineraryId: itineraryState.current!.id,
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
                          progressPhase: msg.progressPhase,
                          selectedActionId: msg.selectedActionId,
                          actionsLocked: msg.actionsLocked,
                          disclaimerText: msg.disclaimerText,
                          onAction: actionsLocked
                              ? null
                              : (action) => _handleAction(context, ref, action),
                          onOpenItinerary: (id) =>
                              _openItineraryDetail(context, itineraryId: id),
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
                  if (waitingForFirstStreamEvent)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 14 : 20,
                        6,
                        isMobile ? 14 : 20,
                        0,
                      ),
                      child: const _GeneratingItineraryIndicator(),
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
    await ref.read(chatProvider.notifier).handleCandidateSelection(candidate);
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    MessageAction action,
  ) async {
    if (action.isViewProgress) {
      await ref.read(chatProvider.notifier).startPendingStreamingItinerary();
      return;
    }
    if (action.isRetryStreaming) {
      await ref.read(chatProvider.notifier).retryStreamingItinerary();
      return;
    }
    if (action.id == ChatNotifier.contextualGenerateActionId) {
      final notifier = ref.read(chatProvider.notifier);
      notifier.lockExistingActions(action);
      final itineraryId = await notifier.generateItinerary();
      if (!context.mounted || itineraryId == null) {
        return;
      }
      await _openItineraryDetail(context, itineraryId: itineraryId);
      return;
    }
    if (action.type == 'navigation') {
      await _openItineraryDetail(
        context,
        itineraryId: _resolveItineraryActionId(ref, action),
      );
      return;
    }
    final completed = await ref
        .read(chatProvider.notifier)
        .handleAction(action);
    if (!context.mounted) {
      return;
    }
    if (completed && action.isGenerate) {
      await _openItineraryDetail(
        context,
        itineraryId: _resolveItineraryActionId(ref, action),
      );
    }
  }

  String? _resolveItineraryActionId(WidgetRef ref, MessageAction action) {
    final actionId = _readItineraryId(action.id);
    if (actionId != null) {
      return actionId;
    }

    final promptId = _readItineraryId(action.prompt);
    if (promptId != null) {
      return promptId;
    }

    return ref.read(itineraryProvider).current?.id;
  }

  Future<void> _openItineraryDetail(
    BuildContext context, {
    String? itineraryId,
  }) async {
    final normalizedId = itineraryId?.trim();
    if (_isOpeningItinerary) {
      return;
    }
    if (normalizedId == null || normalizedId.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No encontramos el itinerario para abrirlo.'),
        ),
      );
      return;
    }

    _isOpeningItinerary = true;
    try {
      await context.pushNamedSafe(
        AppRouteNames.itineraryDetail,
        pathParameters: {'id': normalizedId},
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos abrir el itinerario. Intenta nuevamente.',
            ),
          ),
        );
      }
    } finally {
      _isOpeningItinerary = false;
    }
  }

  String? _readItineraryId(String value) {
    final match = RegExp(
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    ).firstMatch(value);
    return match?.group(0);
  }
}

class _GeneratingItineraryIndicator extends StatefulWidget {
  const _GeneratingItineraryIndicator();

  @override
  State<_GeneratingItineraryIndicator> createState() =>
      _GeneratingItineraryIndicatorState();
}

class _GeneratingItineraryIndicatorState
    extends State<_GeneratingItineraryIndicator> {
  int _dots = 1;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => _dots = _dots == 3 ? 1 : _dots + 1);
      _tick();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedOpacity(
      opacity: 1,
      duration: AppDurations.short,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Generando itinerario${List.filled(_dots, '.').join()}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
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
