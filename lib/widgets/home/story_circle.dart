import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class StoryCircle extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final bool hasStory;
  final VoidCallback? onTap;

  const StoryCircle({
    super.key,
    required this.name,
    this.imageUrl,
    this.hasStory = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 67.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 67×67 circle, 2px solid #DBC483 border
            Container(
              width: 67.w,
              height: 67.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      hasStory ? const Color(0xFFDBC483) : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.asset(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.person, size: 24.sp, color: Colors.grey),
    );
  }
}
