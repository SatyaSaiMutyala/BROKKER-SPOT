import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

/// Plays a network video cached to disk, with a memory-safe lifecycle.
///
/// CRITICAL: the underlying [VideoPlayerController] (an ExoPlayer + hardware
/// decoder + image surface) is created ONLY while [active] is true and is
/// fully disposed the moment [active] becomes false. So in a feed only the
/// visible card holds a decoder — keeping many videos "alive" at once causes
/// OutOfMemory crashes.
///
/// First play downloads the file once via [DefaultCacheManager]; later plays
/// read the cached file (no re-download). Loops by default (replays on end).
class CachedVideoPlayer extends StatefulWidget {
  final String url;

  /// Whether this video should be live (visible & should play). When false
  /// the controller is released entirely and the [placeholder] is shown.
  final bool active;
  final bool loop;
  final bool muted;
  final BoxFit fit;
  final Widget? placeholder;

  /// Tap to mute/unmute (detail screen).
  final bool tapToToggleMute;

  /// Tap to pause/resume. Shows a play icon only while paused.
  final bool tapToTogglePlay;

  const CachedVideoPlayer({
    super.key,
    required this.url,
    this.active = true,
    this.loop = true,
    this.muted = true,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.tapToToggleMute = false,
    this.tapToTogglePlay = false,
  });

  /// No-op kept for compatibility — old views call
  /// `NotificationListener<ScrollNotification>` → `notifyScroll(n)`. The
  /// gating logic was removed; this is just a passthrough so those views
  /// don't need to be edited.
  static void notifyScroll(Object _) {}

  @override
  State<CachedVideoPlayer> createState() => _CachedVideoPlayerState();
}

class _CachedVideoPlayerState extends State<CachedVideoPlayer> {
  VideoPlayerController? _ctrl;
  bool _ready = false;
  late bool _muted = widget.muted;
  bool _userPaused = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _create();
  }

  Future<void> _create() async {
    if (_ctrl != null) return;
    try {
      final file = await DefaultCacheManager().getSingleFile(widget.url);
      if (!mounted || !widget.active) return;
      final ctrl = VideoPlayerController.file(file);
      await ctrl.initialize();
      if (!mounted || !widget.active) {
        ctrl.dispose();
        return;
      }
      ctrl
        ..setLooping(widget.loop)
        ..setVolume(_muted ? 0 : 1);
      if (!_userPaused) ctrl.play();
      setState(() {
        _ctrl = ctrl;
        _ready = true;
      });
    } catch (_) {
      // Leave placeholder on failure.
    }
  }

  void _releaseController() {
    _ctrl?.dispose();
    _ctrl = null;
    if (mounted) {
      setState(() => _ready = false);
    } else {
      _ready = false;
    }
  }

  void _applyPlayState() {
    final ctrl = _ctrl;
    if (ctrl == null || !_ready) return;
    final shouldPlay = widget.active && !_userPaused;
    if (shouldPlay && !ctrl.value.isPlaying) ctrl.play();
    if (!shouldPlay && ctrl.value.isPlaying) ctrl.pause();
  }

  @override
  void didUpdateWidget(CachedVideoPlayer old) {
    super.didUpdateWidget(old);
    if (widget.active && _ctrl == null) {
      _create();
    } else if (!widget.active && _ctrl != null) {
      _releaseController();
    } else {
      _applyPlayState();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _toggleMute() {
    final ctrl = _ctrl;
    if (ctrl == null) return;
    setState(() {
      _muted = !_muted;
      ctrl.setVolume(_muted ? 0 : 1);
    });
  }

  void _togglePlay() {
    setState(() => _userPaused = !_userPaused);
    _applyPlayState();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    if (!_ready || ctrl == null) {
      return widget.placeholder ?? Container(color: Colors.grey.shade300);
    }

    Widget player = FittedBox(
      fit: widget.fit,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: ctrl.value.size.width,
        height: ctrl.value.size.height,
        child: VideoPlayer(ctrl),
      ),
    );

    if (widget.tapToTogglePlay) {
      return Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          player,
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _togglePlay,
            ),
          ),
          if (_userPaused)
            IgnorePointer(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 32),
              ),
            ),
        ],
      );
    }

    if (widget.tapToToggleMute) {
      return Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          player,
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleMute,
            ),
          ),
        ],
      );
    }

    return player;
  }
}
