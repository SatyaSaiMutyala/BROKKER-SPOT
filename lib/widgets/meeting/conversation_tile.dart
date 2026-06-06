import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/conversation_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// One row on the "Announcement → Conversations" screen.
class ConversationTile extends StatelessWidget {
  final ConversationItem conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = conversation.user;
    final url = user.profileImageUrl ?? '';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            ClipOval(
              child: url.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: url,
                      width: 48.w,
                      height: 48.w,
                      fit: BoxFit.cover,
                      // Decode only what we render — these avatars are ~48dp;
                      // downloading + decoding a 2 MP photo for that is what
                      // makes the row sit grey for seconds.
                      memCacheWidth: 144,
                      memCacheHeight: 144,
                      maxWidthDiskCache: 300,
                      maxHeightDiskCache: 300,
                      fadeInDuration: Duration.zero,
                      placeholderFadeInDuration: Duration.zero,
                      errorWidget: (_, __, ___) => _avatarFallback(),
                      placeholder: (_, __) => _avatarFallback(),
                    )
                  : _avatarFallback(),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? 'User',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    conversation.lastMessage?.trim().isNotEmpty == true
                        ? conversation.lastMessage!
                        : 'Tap to start a chat',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _relative(conversation.lastMessageAt),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
                SizedBox(height: 4.h),
                if (conversation.unseenCount > 0)
                  Container(
                    constraints: BoxConstraints(minWidth: 18.w),
                    height: 18.w,
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Text(
                      conversation.unseenCount > 9
                          ? '9+'
                          : '${conversation.unseenCount}',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() => Container(
        width: 48.w,
        height: 48.w,
        color: Colors.grey.shade200,
        child: Icon(Icons.person_outline, color: Colors.grey.shade400),
      );

  static String _relative(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}
