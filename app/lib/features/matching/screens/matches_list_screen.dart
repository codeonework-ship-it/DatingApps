import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/safety_actions_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../common/screens/moderation_appeals_screen.dart';
import '../../common/widgets/report_user_sheet.dart';
import '../providers/match_provider.dart';
import '../widgets/match_card.dart';
import '../../messaging/screens/chat_screen.dart';

class MatchesListScreen extends ConsumerStatefulWidget {
  const MatchesListScreen({super.key});

  @override
  ConsumerState<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends ConsumerState<MatchesListScreen> {
  static const double _matchItemExtent = 104;

  late final ScrollController _scrollController;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (!mounted) {
          return;
        }
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(matchNotifierProvider);
    final matchNotifier = ref.read(matchNotifierProvider.notifier);
    final bottomClearance = MediaQuery.of(context).padding.bottom + 104;

    return Scaffold(
      body: PostLoginBackdrop(
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                snap: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                title: Text(
                  'Your Matches',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.7),
                        blur: AppTheme.glassBlurUltra,
                        crystalEffect: true,
                        child: Text(
                          '${matchState.matches.length} matches',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Matches List or Empty State
              if (matchState.isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.trustBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading matches...',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textDark),
                        ),
                      ],
                    ),
                  ),
                )
              else if (matchState.matches.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.trustBlue.withValues(alpha: 0.12),
                          ),
                          child: const Icon(
                            Icons.favorite_border,
                            color: AppTheme.trustBlue,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No matches yet',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          matchState.trustFilterActive &&
                                  matchState.trustFilteredOutCount > 0
                              ? 'Trust filters hid ${matchState.trustFilteredOutCount} match(es). Try relaxing trust filters from Discover.'
                              : 'Start swiping to find your match!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.textGrey.withValues(alpha: 0.9),
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final match = matchState.matches[index];
                    final scrollProgress =
                        ((index * _matchItemExtent) - _scrollOffset) /
                        _matchItemExtent;
                    final clamped = scrollProgress.clamp(-1.0, 1.0).toDouble();
                    final distance = clamped.abs();
                    final eased = Curves.easeOutCubic.transform(
                      (1 - distance).clamp(0.0, 1.0),
                    );
                    final tilt = clamped * 0.16;
                    final scale = 0.84 + (eased * 0.16);
                    final opacity = 0.62 + (eased * 0.38);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Opacity(
                        opacity: opacity.clamp(0.62, 1.0),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0026)
                            ..rotateX(tilt)
                            ..scale(scale, scale),
                          child: GestureDetector(
                            onLongPress: () {
                              showModalBottomSheet<void>(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (sheetContext) =>
                                    _buildMatchOptionsSheet(
                                      pageContext: context,
                                      sheetContext: sheetContext,
                                      ref: ref,
                                      match: match,
                                      matchNotifier: matchNotifier,
                                    ),
                              );
                            },
                            child: MatchCard(
                              match: match,
                              onTap: () {
                                matchNotifier.markAsRead(match.id);
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ChatScreen(
                                      matchId: match.id,
                                      otherUserId: match.userId,
                                      userName: match.userName,
                                      userPhotoUrl: match.userPhoto,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: matchState.matches.length),
                ),

              // Bottom spacing
              SliverPadding(padding: EdgeInsets.only(bottom: bottomClearance)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchOptionsSheet({
    required BuildContext pageContext,
    required BuildContext sheetContext,
    required WidgetRef ref,
    required Match match,
    required MatchNotifier matchNotifier,
  }) => GlassContainer(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    backgroundColor: Colors.white.withValues(alpha: 0.9),
    blur: 10,
    borderRadius: const BorderRadius.all(Radius.circular(24)),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.textHint.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        ListTile(
          leading: const Icon(Icons.block, color: AppTheme.errorRed),
          title: const Text('Unmatch'),
          onTap: () {
            matchNotifier.unmatch(match.id);
            Navigator.pop(sheetContext);
          },
        ),
        ListTile(
          leading: const Icon(
            Icons.flag_rounded,
            color: AppTheme.warningOrange,
          ),
          title: const Text('Report'),
          onTap: () {
            Navigator.pop(sheetContext);
            Future<void>.delayed(Duration.zero, () async {
              final reportId = await showReportUserSheet(
                context: pageContext,
                onSubmit: ({required reason, description}) async => ref
                      .read(safetyActionsProvider)
                      .reportUser(
                        reportedUserId: match.userId,
                        reason: reason,
                        description: description,
                      ),
              );

              if (!pageContext.mounted) return;
              ScaffoldMessenger.of(pageContext).showSnackBar(
                SnackBar(
                  content: const Text('Report submitted. Thank you.'),
                  action: SnackBarAction(
                    label: 'Appeal',
                    onPressed: () {
                      Navigator.of(pageContext).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ModerationAppealsScreen(
                            initialReason:
                                'Review moderation outcome for report on user ${match.userId}',
                            initialReportId: reportId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            });
          },
        ),
      ],
    ),
  );
}
