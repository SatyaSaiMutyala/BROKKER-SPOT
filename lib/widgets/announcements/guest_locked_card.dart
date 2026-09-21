import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Wraps the last announcement card the viewer is allowed to see and frosts
/// it over with a prompt, so the feed itself shows that more listings exist
/// instead of interrupting the scroll with a dialog.
///
/// Two viewers see this: a guest, who is asked to log in, and a signed-in
/// account that has not finished its broker profile, which is asked to finish
/// it. Same frost, same cap — only [message] and [buttonLabel] differ.
///
/// The wrapped [child] still paints underneath — that blurred glimpse of a
/// real listing is the point — but it is inert: taps only reach [onTap].
/// The line the frost carries. Both viewers read the same thing: what is
/// behind it is the same listings either way.
const String kLockedCardMessage = 'TO VIEW MORE USER\nPROPERTIES PLEASE';

class GuestLockedCard extends StatelessWidget {
  final Widget child;

  /// Matches the wrapped card's outer radius so the frost stops at its edge.
  final double radius;

  final VoidCallback onTap;

  /// The line above the button. Line breaks are kept as written — the copy is
  /// centred over a photo, so where it wraps is a design decision.
  final String message;

  final String buttonLabel;

  const GuestLockedCard({
    super.key,
    required this.child,
    required this.onTap,
    this.message = kLockedCardMessage,
    this.buttonLabel = 'Login',
    this.radius = 20,
  });

  static const Color _gold = Color(0xFFC8AF69);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius.r),
      child: Stack(
        // The list hands its children a tight width. A loose Stack would drop
        // that and let the card fall back to its own narrower intrinsic width,
        // so the locked card would sit narrower than every other one.
        fit: StackFit.passthrough,
        children: [
          // The card is blurred directly rather than through a BackdropFilter:
          // inside a scrolling list the backdrop variant samples whatever the
          // compositor happens to have painted below, which is unreliable.
          // Filtering the child itself always frosts exactly this card.
          IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 3,
                sigmaY: 3,
                // Without clamping, the blur samples transparency from beyond
                // the card and its edges fade out.
                tileMode: TileMode.clamp,
              ),
              child: child,
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                // A light dark wash rather than a heavy scrim — the listing
                // stays recognisable behind the frost, just out of reach, and
                // the white copy keeps its contrast over bright photos.
                color: const Color(0x33000000),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46.w,
                      height: 46.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _gold,
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: Icon(
                        Icons.apartment_rounded,
                        size: 32.sp,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 9.h),
                    Text(
                      'TO VIEW MORE USER\nPROPERTIES PLEASE',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                        height: 1.45,
                        // The frost keeps some of the listing's own contrast,
                        // so a soft halo keeps the copy readable over a bright
                        // photo without darkening the whole card.
                        shadows: const [
                          Shadow(color: Color(0x4D000000), blurRadius: 6),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),
                    GestureDetector(
                      onTap: onTap,
                      behavior: HitTestBehavior.opaque,
                      // A pill that hugs its label, whichever label it is.
                      //
                      // IntrinsicWidth is what keeps it hugging: the Column
                      // hands its children the full width to use, and a
                      // Container with an `alignment` takes all of it unless
                      // its width is pinned. It was pinned at 90 while the
                      // only label was "Login"; unpinning that for "Complete
                      // Profile" is what stretched the pill across the card.
                      child: IntrinsicWidth(
                        child: Container(
                          // Still no narrower than the original pill, so a
                          // short label doesn't shrink to a stub.
                          constraints: BoxConstraints(minWidth: 90.w),
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          height: 30.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _gold,
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          child: Text(
                            buttonLabel,
                            maxLines: 1,
                            style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
