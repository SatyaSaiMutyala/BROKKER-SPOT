import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CachedVideoPlayer extends StatefulWidget {
  final String url;
  final bool active;
  final bool loop;
  final bool muted;
  final BoxFit fit;
  final Widget? placeholder;
  final bool tapToToggleMute;
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

  static void notifyScroll(Object _) {}

  @override
  CachedVideoPlayerState createState() => CachedVideoPlayerState();
}

/// Public so callers can hold a [GlobalKey<CachedVideoPlayerState>] and call
/// [forceStop] to synchronously silence the video before a route transition.
class CachedVideoPlayerState extends State<CachedVideoPlayer> {
  // Static counter so every instance gets a unique ID that appears in every
  // log line — makes it trivial to tell which state owns which log entry.
  static int _nextId = 0;
  final int _id = _nextId++;

  VideoPlayerController? _ctrl;
  bool _ready = false;
  late bool _muted = widget.muted;
  bool _userPaused = false;
  int _generation = 0;

  String get _tag => widget.url.split('/').last;
  String get _pfx => '🎬 [Video#$_id gen=$_generation]';

  @override
  void initState() {
    super.initState();
    debugPrint('$_pfx initState active=${widget.active} muted=${widget.muted} url=$_tag');
    if (widget.active) _create();
  }

  Future<void> _create() async {
    if (_ctrl != null) return;
    final gen = _generation;
    debugPrint('🎬 [Video#$_id gen=$_generation] _create() starting url=$_tag');
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await ctrl.initialize();
      // Cancel if: unmounted, generation moved on, widget deactivated, OR another
      // concurrent _create() already won the race and set _ctrl first.
      if (!mounted || _generation != gen || !widget.active || _ctrl != null) {
        debugPrint('🎬 [Video#$_id] _create() CANCELLED gen_now=$_generation captured=$gen mounted=$mounted active=${widget.active} ctrl_taken=${_ctrl != null} url=$_tag');
        ctrl.setVolume(0);
        ctrl.dispose();
        return;
      }
      // Assign _ctrl BEFORE play() so dispose() can always find and clean it up.
      _ctrl = ctrl;
      _ctrl!.setLooping(widget.loop);
      _ctrl!.setVolume(_muted ? 0 : 1);
      if (!_userPaused) _ctrl!.play();
      debugPrint('🎬 [Video#$_id gen=$_generation] PLAYING muted=$_muted url=$_tag');
      if (mounted) setState(() => _ready = true);
    } catch (e, s) {
      debugPrint('❌ [Video#$_id] error url=$_tag: $e\n$s');
    }
  }

  /// Immediately silences and releases the controller. Safe to call from a
  /// parent's [State.dispose] (no [setState] is issued). Also increments the
  /// generation so any in-flight [_create] will discard its result.
  void forceStop() {
    _generation++;
    debugPrint('🎬 [Video#$_id gen=$_generation] forceStop() ctrl=${_ctrl != null ? "SET" : "NULL"} url=$_tag');
    _ctrl?.setVolume(0);
    _ctrl?.pause();
    _ctrl?.dispose();
    _ctrl = null;
    _ready = false;
  }

  void _releaseController() {
    _generation++;
    debugPrint('🎬 [Video#$_id gen=$_generation] _releaseController() ctrl=${_ctrl != null ? "SET" : "NULL"} url=$_tag');
    _ctrl?.setVolume(0);
    _ctrl?.pause();
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
  void didUpdateWidget(CachedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('🎬 [Video#$_id gen=$_generation] didUpdateWidget active=${widget.active} was=${oldWidget.active} ctrl=${_ctrl != null ? "SET" : "NULL"} url=$_tag');
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
    _generation++;
    debugPrint('🎬 [Video#$_id gen=$_generation] dispose() ctrl=${_ctrl != null ? "SET" : "NULL"} url=$_tag');
    _ctrl?.setVolume(0);
    _ctrl?.pause();
    _ctrl?.dispose();
    _ctrl = null;
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
