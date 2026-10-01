import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/app/bootstrap/app_environment.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/core/constants/app_info.dart';
import 'package:forge_gym/core/media/media_cache.dart';
import 'package:forge_gym/core/notifications/push_service.dart';
import 'package:forge_gym/core/utils/formatters.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/auth/domain/entities/fitness_level.dart';
import 'package:forge_gym/features/auth/domain/entities/user.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:forge_gym/features/profile/domain/entities/gym_info.dart';
import 'package:forge_gym/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:forge_gym/features/profile/presentation/cubit/profile_state.dart';

/// Member profile: identity, editable body stats (with BMI), gym
/// information, notification preferences, and sign out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileCubit>()..load(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage &&
            current.errorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        builder: (context, state) {
          return switch (state.status) {
            ProfileStatus.initial ||
            ProfileStatus.loading => AppSkeletonList.dashboard(),
            ProfileStatus.error => AppErrorView(
              message: state.errorMessage ?? 'Something went wrong.',
              onRetry: () => context.read<ProfileCubit>().load(),
            ),
            ProfileStatus.loaded ||
            ProfileStatus.saving => _Loaded(state: state),
          };
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state});

  final ProfileState state;

  @override
  Widget build(BuildContext context) {
    final user = state.user;
    var reveal = 0;
    // A plain column (not a lazy list): the page is short and every
    // section — including Sign out — must exist for accessibility scans.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppReveal(
            index: reveal++,
            child: _HeaderCard(user: user),
          ),
          if (user != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xxl),
            AppReveal(
              index: reveal++,
              child: _BodyStats(user: user),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          AppReveal(index: reveal++, child: const _GymSection()),
          const SizedBox(height: AppSpacing.xxl),
          AppReveal(
            index: reveal++,
            child: _NotificationSection(state: state),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppReveal(index: reveal++, child: const _StorageSection()),
          const SizedBox(height: AppSpacing.xxl),
          AppReveal(index: reveal++, child: const _SignOut()),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _versionLabel(),
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// `Forge Gym v0.2.0 (2) · dev` — every part is optional so the label is
/// never wrong, only shorter.
String _versionLabel() {
  final parts = <String>['Forge Gym'];
  if (getIt.isRegistered<AppInfo>()) {
    final label = getIt<AppInfo>().label;
    if (label.isNotEmpty) parts.add(label);
  }
  if (getIt.isRegistered<EnvConfig>() && !getIt<EnvConfig>().isProduction) {
    parts.add('· ${getIt<EnvConfig>().environment.name}');
  }
  return parts.join(' ');
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'Member';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Semantics(
      label: user != null
          ? 'Signed in as ${user!.name}, ${user!.email}, '
                '${user!.fitnessLevel.label} level'
          : 'Profile',
      explicitChildNodes: false,
      child: AppPhotoHero(
        imageAsset: 'assets/exercises/shoulder-press-dumbbell/thumb.jpg',
        child: Row(
          children: <Widget>[
            Container(
              width: 68,
              height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: Text(
                initial,
                style: AppTextStyles.headline.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    style: AppTextStyles.headline.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      user!.email,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.bolt_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user!.fitnessLevel.label,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body stats + BMI
// ---------------------------------------------------------------------------

class _BodyStats extends StatelessWidget {
  const _BodyStats({required this.user});

  final User user;

  Future<void> _edit(
    BuildContext context, {
    required String title,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
    required String initialValue,
    required bool isDecimal,
    required double min,
    required double max,
    required ValueChanged<double> onSave,
  }) async {
    final value = await showAppInputSheet(
      context,
      title: title,
      label: label,
      hint: hint,
      suffixText: suffix,
      icon: icon,
      initialValue: initialValue,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      validator: (text) {
        final normalised = text.replaceAll(',', '.');
        final parsed = isDecimal
            ? double.tryParse(normalised)
            : int.tryParse(normalised)?.toDouble();
        if (parsed == null || parsed < min || parsed > max) {
          return 'Enter a value between ${Formatters.number(min)} and '
              '${Formatters.number(max)} $suffix.';
        }
        return null;
      },
    );
    if (value == null) return;
    onSave(double.parse(value.replaceAll(',', '.')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<ProfileCubit>();
    final age = user.age;
    final height = user.heightCm;
    final weight = user.weightKg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: 'Body stats',
          padding: EdgeInsets.zero,
          trailing: Text(
            'Tap to edit',
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: AppStatTile(
                icon: Icons.cake_outlined,
                value: (age ?? 0).toDouble(),
                label: 'Age',
                format: (v) => v < 0.5 ? '—' : '${v.round()}',
                semanticLabel: age != null
                    ? 'Age $age years. Tap to edit.'
                    : 'Age not set. Tap to edit.',
                onTap: () => _edit(
                  context,
                  title: 'Your age',
                  label: 'Age',
                  hint: 'e.g. 30',
                  suffix: 'years',
                  icon: Icons.cake_outlined,
                  initialValue: age?.toString() ?? '',
                  isDecimal: false,
                  min: 10,
                  max: 120,
                  onSave: (v) => cubit.updateStats(age: v.toInt()),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppStatTile(
                icon: Icons.height_rounded,
                value: height ?? 0,
                label: 'Height (cm)',
                format: (v) => v < 0.5 ? '—' : Formatters.number(v),
                tint: scheme.tertiary,
                semanticLabel: height != null
                    ? 'Height ${Formatters.number(height)} centimetres. Tap to edit.'
                    : 'Height not set. Tap to edit.',
                onTap: () => _edit(
                  context,
                  title: 'Your height',
                  label: 'Height',
                  hint: 'e.g. 178',
                  suffix: 'cm',
                  icon: Icons.height_rounded,
                  initialValue: height != null ? Formatters.number(height) : '',
                  isDecimal: true,
                  min: 50,
                  max: 272,
                  onSave: (v) => cubit.updateStats(heightCm: v),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppStatTile(
                icon: Icons.monitor_weight_outlined,
                value: weight ?? 0,
                label: 'Weight (kg)',
                format: (v) => v < 0.5 ? '—' : Formatters.number(v),
                tint: scheme.secondary,
                semanticLabel: weight != null
                    ? 'Weight ${Formatters.number(weight)} kilograms. Tap to edit.'
                    : 'Weight not set. Tap to edit.',
                onTap: () => _edit(
                  context,
                  title: 'Your weight',
                  label: 'Weight',
                  hint: 'e.g. 82.5',
                  suffix: 'kg',
                  icon: Icons.monitor_weight_outlined,
                  initialValue: weight != null ? Formatters.number(weight) : '',
                  isDecimal: true,
                  min: 1,
                  max: 500,
                  onSave: (v) => cubit.updateStats(weightKg: v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          child: height != null && weight != null && height > 0
              ? _BmiCard(
                  key: const ValueKey('bmi'),
                  heightCm: height,
                  weightKg: weight,
                )
              : const _HintCard(
                  key: ValueKey('bmi-hint'),
                  text: 'Add your height and weight to see your BMI range.',
                ),
        ),
      ],
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// BMI with a segmented range bar. Informational only — the copy avoids
/// medical judgement and the categories follow the WHO adult ranges.
class _BmiCard extends StatelessWidget {
  const _BmiCard({super.key, required this.heightCm, required this.weightKg});

  final double heightCm;
  final double weightKg;

  double get bmi {
    final metres = heightCm / 100;
    return weightKg / (metres * metres);
  }

  static const _segments = <({String label, double from, double to})>[
    (label: 'Under', from: 14, to: 18.5),
    (label: 'Healthy', from: 18.5, to: 25),
    (label: 'Over', from: 25, to: 30),
    (label: 'High', from: 30, to: 40),
  ];

  String get category {
    final value = bmi;
    if (value < 18.5) return 'Below the typical range';
    if (value < 25) return 'Within the typical range';
    if (value < 30) return 'Above the typical range';
    return 'Well above the typical range';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = bmi;
    final position = ((value - 14) / (40 - 14)).clamp(0.0, 1.0);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final colours = <Color>[
      scheme.tertiary.withValues(alpha: 0.55),
      AppColors.success,
      AppColors.warning,
      scheme.error,
    ];
    return AppCard(
      semanticLabel: 'BMI ${value.toStringAsFixed(1)}. $category.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              const Text('BMI', style: AppTextStyles.subtitle),
              const Spacer(),
              AppCountUp(
                value: value,
                format: (v) => v.toStringAsFixed(1),
                style: AppTextStyles.headline.copyWith(color: scheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            category,
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return SizedBox(
                height: 22,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 7,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: Row(
                          children: <Widget>[
                            for (var i = 0; i < _segments.length; i++)
                              Expanded(
                                flex:
                                    ((_segments[i].to - _segments[i].from) * 10)
                                        .round(),
                                child: Container(height: 8, color: colours[i]),
                              ),
                          ],
                        ),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: position),
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, child) => Positioned(
                        left: (width * t - 11).clamp(0.0, width - 22),
                        top: 0,
                        child: child!,
                      ),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.onSurface, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              for (final segment in _segments)
                Expanded(
                  flex: ((segment.to - segment.from) * 10).round(),
                  child: Text(
                    segment.label,
                    style: AppTextStyles.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gym information
// ---------------------------------------------------------------------------

class _GymSection extends StatefulWidget {
  const _GymSection();

  @override
  State<_GymSection> createState() => _GymSectionState();
}

class _GymSectionState extends State<_GymSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(title: 'Your gym', padding: EdgeInsets.zero),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          onTap: () => setState(() => _expanded = !_expanded),
          semanticLabel:
              'Gym information for ${kGymInfo.name}. '
              '${_expanded ? 'Collapse' : 'Expand'}.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.storefront_outlined,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(kGymInfo.name, style: AppTextStyles.subtitle),
                        const SizedBox(height: 2),
                        Text(
                          kGymInfo.address,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: !_expanded
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _InfoRow(
                              icon: Icons.schedule_rounded,
                              text: kGymInfo.openingHours,
                            ),
                            _InfoRow(
                              icon: Icons.call_outlined,
                              text: kGymInfo.phone,
                            ),
                            _InfoRow(
                              icon: Icons.mail_outline_rounded,
                              text: kGymInfo.email,
                            ),
                            _InfoRow(
                              icon: Icons.language_rounded,
                              text: kGymInfo.website,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'Facilities',
                              style: AppTextStyles.subtitle,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: <Widget>[
                                for (final facility in kGymInfo.facilities)
                                  _Pill(text: facility),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'House rules',
                              style: AppTextStyles.subtitle,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            for (final rule in kGymInfo.rules)
                              _InfoRow(
                                icon: Icons.check_circle_outline_rounded,
                                text: rule,
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: scheme.onSurface),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

class _NotificationSection extends StatelessWidget {
  const _NotificationSection({required this.state});

  final ProfileState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<ProfileCubit>();
    final prefs = state.preferences;
    final saving = state.status == ProfileStatus.saving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(
          title: 'Notifications',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            children: <Widget>[
              _ToggleRow(
                icon: Icons.alarm_rounded,
                title: 'Workout reminders',
                subtitle: 'Gentle nudges to keep your routine',
                value: prefs.workoutReminders,
                onChanged: saving
                    ? null
                    : (v) => cubit.savePreferences(
                        prefs.copyWith(workoutReminders: v),
                      ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: prefs.workoutReminders
                    ? _ReminderTimeRow(
                        hour: prefs.reminderHour,
                        minute: prefs.reminderMinute,
                        enabled: !saving,
                        onChanged: (time) => cubit.savePreferences(
                          prefs.copyWith(
                            reminderHour: time.hour,
                            reminderMinute: time.minute,
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              Divider(height: 1, color: scheme.outlineVariant),
              _ToggleRow(
                icon: Icons.campaign_outlined,
                title: 'Gym announcements',
                subtitle: 'News, new classes, and schedule changes',
                value: prefs.announcements,
                onChanged: saving
                    ? null
                    : (v) => cubit.savePreferences(
                        prefs.copyWith(announcements: v),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  0,
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        getIt.isRegistered<PushService>() &&
                                getIt<PushService>().isAvailable
                            ? 'Reminders are scheduled on this phone and '
                                  'work offline. Announcements arrive as '
                                  'push notifications from the gym.'
                            : 'Reminders are scheduled on this phone and '
                                  'work offline. Announcements need the '
                                  'gym\'s push service and will start once '
                                  'it is connected.',
                        style: AppTextStyles.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 20, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTextStyles.subtitle),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sign out
// ---------------------------------------------------------------------------

class _SignOut extends StatelessWidget {
  const _SignOut();

  Future<void> _confirm(BuildContext context) async {
    final auth = context.read<AuthCubit>();
    final confirmed = await showAppConfirmSheet(
      context,
      title: 'Sign out?',
      message:
          'Your workouts and progress stay on this device. '
          'Sign back in any time to continue.',
      confirmLabel: 'Yes, sign out',
      cancelLabel: 'Stay signed in',
      icon: Icons.logout_rounded,
      destructive: true,
    );
    if (confirmed == true) await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Sign out',
      variant: AppButtonVariant.outline,
      icon: Icons.logout_rounded,
      onPressed: () => _confirm(context),
    );
  }
}

// ---------------------------------------------------------------------------
// Reminder time
// ---------------------------------------------------------------------------

class _ReminderTimeRow extends StatelessWidget {
  const _ReminderTimeRow({
    required this.hour,
    required this.minute,
    required this.enabled,
    required this.onChanged,
  });

  final int hour;
  final int minute;
  final bool enabled;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = TimeOfDay(hour: hour, minute: minute);
    return InkWell(
      onTap: !enabled
          ? null
          : () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
                helpText: 'Daily reminder time',
              );
              if (picked != null) onChanged(picked);
            },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          52 + AppSpacing.md,
          0,
          0,
          AppSpacing.sm,
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.schedule_rounded, size: 16, color: scheme.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Remind me at ${time.format(context)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.edit_outlined, size: 14, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Storage
// ---------------------------------------------------------------------------

/// Downloaded demo clips live on the device; this lets members see how
/// much space they take and free it (clips re-download on next open).
class _StorageSection extends StatefulWidget {
  const _StorageSection();

  @override
  State<_StorageSection> createState() => _StorageSectionState();
}

class _StorageSectionState extends State<_StorageSection> {
  MediaCache? get _cache =>
      getIt.isRegistered<MediaCache>() ? getIt<MediaCache>() : null;
  late Future<int> _bytes = _cache?.sizeBytes() ?? Future<int>.value(0);

  static String _format(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _clear() async {
    final cache = _cache;
    if (cache == null) return;
    final confirmed = await showAppConfirmSheet(
      context,
      title: 'Remove downloaded videos?',
      message:
          'Frees the space on your phone. Any demo you open again will '
          'download once more.',
      confirmLabel: 'Remove videos',
      cancelLabel: 'Keep them',
      icon: Icons.delete_sweep_outlined,
      destructive: true,
    );
    if (confirmed != true) return;
    await cache.clear();
    if (mounted) setState(() => _bytes = cache.sizeBytes());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_cache == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(title: 'Storage', padding: EdgeInsets.zero),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: FutureBuilder<int>(
            future: _bytes,
            builder: (context, snapshot) {
              final bytes = snapshot.data ?? 0;
              return Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.sd_storage_outlined,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Downloaded demo videos',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bytes == 0
                              ? 'Nothing downloaded yet'
                              : '${_format(bytes)} on this phone',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (bytes > 0)
                    TextButton(onPressed: _clear, child: const Text('Clear')),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
