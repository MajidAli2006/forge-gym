import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/challenges/domain/entities/challenge.dart';
import 'package:forge_gym/features/challenges/presentation/cubit/challenges_cubit.dart';
import 'package:forge_gym/features/challenges/presentation/cubit/challenges_state.dart';
import 'package:forge_gym/features/challenges/presentation/widgets/challenge_card.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';

/// Joinable challenges: active ones with live progress, the catalogue to
/// join, and completed badges.
class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChallengesCubit>()..load(),
      child: const _ChallengesView(),
    );
  }
}

class _ChallengesView extends StatelessWidget {
  const _ChallengesView();

  Future<void> _showDetails(
    BuildContext context,
    ChallengeProgress progress,
  ) async {
    final cubit = context.read<ChallengesCubit>();
    final challenge = progress.challenge;
    final joinable =
        progress.status == ChallengeStatus.available ||
        progress.status == ChallengeStatus.expired;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AppSheet(
        icon: ChallengeLook.icon(challenge.icon),
        title: challenge.title,
        message: challenge.description,
        body: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            AppChip(label: challenge.difficulty.label),
            AppChip(label: '${challenge.durationDays} days'),
            AppChip(label: challenge.metric.format(challenge.target)),
            if (challenge.exerciseName != null)
              AppChip(label: challenge.exerciseName!),
          ],
        ),
        actions: <Widget>[
          if (joinable)
            AppButton(
              label: 'Join challenge',
              icon: Icons.add_rounded,
              onPressed: () => Navigator.of(sheetContext).pop(true),
            )
          else if (progress.isActive)
            AppButton(
              label: 'Leave challenge',
              variant: AppButtonVariant.outline,
              onPressed: () => Navigator.of(sheetContext).pop(false),
            ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Close',
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.join(challenge.id);
    if (confirmed == false && progress.isActive) {
      await cubit.leave(challenge.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      body: BlocBuilder<ChallengesCubit, ChallengesState>(
        builder: (context, state) {
          return switch (state.status) {
            ChallengesStatus.initial ||
            ChallengesStatus.loading => AppSkeletonList.cards(coverHeight: 84),
            ChallengesStatus.error => AppErrorView(
              message: state.errorMessage ?? 'Something went wrong.',
              onRetry: () => context.read<ChallengesCubit>().load(),
            ),
            ChallengesStatus.loaded => _Loaded(
              state: state,
              onDetails: (p) => _showDetails(context, p),
            ),
          };
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state, required this.onDetails});

  final ChallengesState state;
  final ValueChanged<ChallengeProgress> onDetails;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChallengesCubit>();
    final scheme = Theme.of(context).colorScheme;
    var reveal = 0;
    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: <Widget>[
          AppReveal(
            index: reveal++,
            child: Text(
              'Pick a goal, and every workout you finish moves the bar. '
              'Progress counts automatically — nothing to log by hand.',
              style: AppTextStyles.body.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (state.active.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            AppReveal(
              index: reveal++,
              child: const AppSectionHeader(
                title: 'Your challenges',
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final p in state.active)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppReveal(
                  index: reveal++,
                  child: ChallengeCard(
                    progress: p,
                    onTap: () => onDetails(p),
                    onLeave: () => cubit.leave(p.challenge.id),
                  ),
                ),
              ),
          ],
          if (state.available.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            AppReveal(
              index: reveal++,
              child: const AppSectionHeader(
                title: 'Join a challenge',
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final p in state.available)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppReveal(
                  index: reveal++,
                  child: ChallengeCard(
                    progress: p,
                    onTap: () => onDetails(p),
                    onJoin: () => cubit.join(p.challenge.id),
                  ),
                ),
              ),
          ],
          if (state.completed.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            AppReveal(
              index: reveal++,
              child: const AppSectionHeader(
                title: 'Completed',
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final p in state.completed)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppReveal(
                  index: reveal++,
                  child: ChallengeCard(progress: p, onTap: () => onDetails(p)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
