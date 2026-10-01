import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/components/app_state_views.dart';
import 'package:forge_gym/design_system/spacing/app_spacing.dart';
import 'package:forge_gym/design_system/typography/app_text_styles.dart';
import 'package:video_player/video_player.dart';

/// Generic short-clip player for bundled exercise demonstrations.
///
/// Owns exactly one [VideoPlayerController]: it initializes in [initState]
/// and is disposed in [dispose]. Never use one instance per list row —
/// lists show thumbnails; this player belongs on detail screens.
///
/// Behavior: muted autoplay on loop by default (appropriate for silent
/// gym demos), with an accessible play/pause + replay + mute control row.
///
/// Sizing: the clip is always drawn at its own aspect ratio (never
/// stretched). Landscape clips fill the available width; portrait clips —
/// the bundled exercise demos are 9:16 — are letterboxed on a dark
/// background and capped at [maxHeight]. [aspectRatio] only sizes the
/// loading/error placeholders shown before the clip's dimensions are known.
class AppVideoPlayer extends StatefulWidget {
  const AppVideoPlayer({
    super.key,
    this.assetPath,
    this.filePath,
    this.autoPlay = true,
    this.looping = true,
    this.muted = true,
    this.aspectRatio = 16 / 9,
    this.maxHeight = 320,
    this.posterAssetPath,
    this.semanticLabel,
    this.onError,
  });

  /// Bundled clip. Exactly one of [assetPath] / [filePath] must be set.
  final String? assetPath;

  /// Clip on the device (e.g. downloaded by `MediaCache`).
  final String? filePath;
  final bool autoPlay;
  final bool looping;
  final bool muted;
  final double aspectRatio;
  final double maxHeight;

  /// Optional still (e.g. the exercise thumbnail) drawn blurred and dimmed
  /// behind a letterboxed clip instead of flat black.
  final String? posterAssetPath;
  final String? semanticLabel;

  /// Called when the clip cannot be initialised (unreadable or corrupt
  /// file). The owner may evict a cached copy and try again.
  final void Function(Object error)? onError;

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer>
    with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  late Future<void> _initialize;
  bool _showControls = false;
  Timer? _hideTimer;

  /// True once the member explicitly paused; we never auto-resume over
  /// that choice.
  bool _userPaused = false;

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  /// Shows the control bar and, while playing, hides it again after a
  /// short idle period so it never covers the demo for long.
  void _revealControls() {
    _hideTimer?.cancel();
    setState(() => _showControls = true);
    if (_controller.value.isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _controller.value.isPlaying) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _toggleControls() {
    if (_showControls) {
      _hideTimer?.cancel();
      setState(() => _showControls = false);
    } else {
      _revealControls();
    }
  }

  VideoPlayerController _createController() {
    final file = widget.filePath;
    // mixWithOthers: the demos are silent by default, so they must not
    // request audio focus. Without this a phone call (or any other audio)
    // pauses the clip and it stays frozen after the call ends.
    final options = VideoPlayerOptions(mixWithOthers: true);
    final controller = file != null
        ? VideoPlayerController.file(File(file), videoPlayerOptions: options)
        : VideoPlayerController.asset(
            widget.assetPath!,
            videoPlayerOptions: options,
          );
    controller.addListener(_onControllerChanged);
    return controller
      ..setLooping(widget.looping)
      ..setVolume(widget.muted ? 0 : 1);
  }

  Future<void> _start() {
    return _controller
        .initialize()
        .then((_) {
          if (widget.autoPlay && mounted) {
            _controller.play();
            setState(() {});
          }
        })
        .catchError((Object error) {
          widget.onError?.call(error);
          // Rethrow so the FutureBuilder shows the error state.
          throw error;
        });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = _createController();
    _initialize = _start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      // Back from a call / another app: pick up where we left off unless
      // the member had paused it themselves.
      if (widget.autoPlay && !_userPaused && !_controller.value.isPlaying) {
        _controller.play();
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.paused) {
      _controller.pause();
    }
  }

  @override
  void didUpdateWidget(AppVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath ||
        oldWidget.filePath != widget.filePath) {
      // Defensive: the widget is meant to be created per clip, but if the
      // source changes we rebuild the controller rather than leak it.
      _controller.removeListener(_onControllerChanged);
      _controller.dispose();
      _controller = _createController();
      _userPaused = false;
      _initialize = _start();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _userPaused = true;
        _hideTimer?.cancel();
        _controller.pause();
      } else {
        _userPaused = false;
        _revealControls();
        if (_controller.value.position >= _controller.value.duration) {
          _controller.seekTo(Duration.zero);
        }
        _controller.play();
      }
    });
  }

  void _replay() {
    _userPaused = false;
    _controller.seekTo(Duration.zero);
    _controller.play();
    setState(() {});
  }

  void _toggleMute() {
    setState(() {
      _controller.setVolume(_controller.value.volume > 0 ? 0 : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel ?? 'Exercise demonstration video',
      child: FutureBuilder<void>(
        future: _initialize,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: const AppLoadingView(message: 'Loading video…'),
            );
          }
          if (snapshot.hasError) {
            return AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: const AppErrorView(
                message:
                    'Video unavailable. Exercise instructions are still available.',
                icon: Icons.videocam_off_outlined,
              ),
            );
          }
          final videoAspectRatio = _controller.value.aspectRatio;
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = math.min(
                width / videoAspectRatio,
                widget.maxHeight,
              );
              return Container(
                width: width,
                height: height,
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    if (widget.posterAssetPath != null)
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Image.asset(
                          widget.posterAssetPath!,
                          fit: BoxFit.cover,
                          color: Colors.black54,
                          colorBlendMode: BlendMode.darken,
                          excludeFromSemantics: true,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleControls,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: videoAspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
                    // Big centre button while paused/ended; the bar handles
                    // everything else.
                    if (!_controller.value.isPlaying)
                      Center(
                        child: _CentreButton(
                          icon:
                              _controller.value.position >=
                                      _controller.value.duration &&
                                  !widget.looping
                              ? Icons.replay_rounded
                              : Icons.play_arrow_rounded,
                          semanticLabel: 'Play video',
                          onPressed: _togglePlayPause,
                        ),
                      ),
                    AnimatedSlide(
                      offset: _showControls || !_controller.value.isPlaying
                          ? Offset.zero
                          : const Offset(0, 1),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: _showControls || !_controller.value.isPlaying
                            ? 1
                            : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _ControlBar(
                            controller: _controller,
                            onPlayPause: _togglePlayPause,
                            onReplay: _replay,
                            onMute: _toggleMute,
                            onInteract: _revealControls,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CentreButton extends StatelessWidget {
  const _CentreButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(
            icon,
            size: 36,
            color: scheme.onPrimary,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}

/// Bottom control bar: play/pause, scrubber with elapsed / total time,
/// replay and mute. Sits on a gradient so it reads over any frame.
class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.controller,
    required this.onPlayPause,
    required this.onReplay,
    required this.onMute,
    required this.onInteract,
  });

  final VideoPlayerController controller;
  final VoidCallback onPlayPause;
  final VoidCallback onReplay;
  final VoidCallback onMute;
  final VoidCallback onInteract;

  static String _clock(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = controller.value;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Colors.transparent, Colors.black87],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Listener(
              onPointerDown: (_) => onInteract(),
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                colors: VideoProgressColors(
                  playedColor: scheme.primary,
                  bufferedColor: Colors.white38,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          ),
          Row(
            children: <Widget>[
              _BarButton(
                icon: value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                semanticLabel: value.isPlaying ? 'Pause video' : 'Play video',
                onPressed: onPlayPause,
              ),
              _BarButton(
                icon: Icons.replay_rounded,
                semanticLabel: 'Replay video',
                onPressed: onReplay,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${_clock(value.position)} / ${_clock(value.duration)}',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const Spacer(),
              _BarButton(
                icon: value.volume > 0
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                semanticLabel: value.volume > 0 ? 'Mute video' : 'Unmute video',
                onPressed: onMute,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 26),
      tooltip: semanticLabel,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }
}
