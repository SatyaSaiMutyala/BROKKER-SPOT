import 'package:brokkerspot/core/common_widget/cached_video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One image or video entry in a [FullscreenMediaViewer] gallery.
class MediaGalleryItem {
  final String url;
  final bool isVideo;

  const MediaGalleryItem({required this.url, required this.isVideo});
}

/// Reusable fullscreen image + video gallery viewer shared by every
/// announcement/property detail screen. Swipe or use the side arrows to
/// move between items — arrows only show on the side that has more to see —
/// with a "current / total" counter up top. Images pinch-zoom; videos play
/// inline with tap-to-pause.
class FullscreenMediaViewer extends StatefulWidget {
  final List<MediaGalleryItem> items;
  final int initialIndex;

  const FullscreenMediaViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  static void show({
    required List<MediaGalleryItem> items,
    int initialIndex = 0,
  }) {
    if (items.isEmpty) return;
    Get.to(
      () => FullscreenMediaViewer(items: items, initialIndex: initialIndex),
      transition: Transition.fadeIn,
    );
  }

  @override
  State<FullscreenMediaViewer> createState() => _FullscreenMediaViewerState();
}

class _FullscreenMediaViewerState extends State<FullscreenMediaViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _current = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = _current + delta;
    if (next < 0 || next >= widget.items.length) return;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: total,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              final item = widget.items[i];
              if (item.isVideo) {
                return Center(
                  child: CachedVideoPlayer(
                    url: item.url,
                    active: i == _current,
                    muted: false,
                    loop: false,
                    fit: BoxFit.contain,
                    tapToTogglePlay: true,
                  ),
                );
              }
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: item.url,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              );
            },
          ),

          // Close button + "current/total" counter.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _roundButton(
                    icon: Icons.close,
                    onTap: () => Get.back(),
                  ),
                  const Spacer(),
                  if (total > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_current + 1}/$total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Balances the close button so the counter stays centered.
                  const SizedBox(width: 38),
                ],
              ),
            ),
          ),

          // Prev arrow — only when there's an earlier item.
          if (_current > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _roundButton(
                  icon: Icons.chevron_left,
                  onTap: () => _go(-1),
                  size: 44,
                  iconSize: 28,
                ),
              ),
            ),

          // Next arrow — only when there's a later item.
          if (_current < total - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _roundButton(
                  icon: Icons.chevron_right,
                  onTap: () => _go(1),
                  size: 44,
                  iconSize: 28,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 38,
    double iconSize = 22,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}
