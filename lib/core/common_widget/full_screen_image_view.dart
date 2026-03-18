import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Reusable full-screen image viewer.
/// Pass [imageUrl] for network images or [assetPath] for assets.
/// Supports pinch-to-zoom via InteractiveViewer.
class FullScreenImageView extends StatelessWidget {
  final String? imageUrl;
  final String? assetPath;

  const FullScreenImageView({super.key, this.imageUrl, this.assetPath})
      : assert(imageUrl != null || assetPath != null,
            'Provide either imageUrl or assetPath');

  static void show({String? imageUrl, String? assetPath}) {
    Get.to(
      () => FullScreenImageView(imageUrl: imageUrl, assetPath: assetPath),
      transition: Transition.fadeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : Image.asset(
                      assetPath!,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => const Icon(Icons.broken_image,
      color: Colors.white54, size: 64);
}
