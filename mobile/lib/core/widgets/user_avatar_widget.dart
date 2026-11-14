import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/api_constants.dart';
import '../utils/avatar_upload_helper.dart';

class UserAvatarWidget extends ConsumerWidget {
  final String? avatarUrl;
  final String? name;
  final String? userId;
  final double size;
  final double borderRadius;
  final bool isCircle;
  final bool canEdit;
  final VoidCallback? onTap;

  const UserAvatarWidget({
    super.key,
    this.avatarUrl,
    this.name,
    this.userId,
    this.size = 36,
    this.borderRadius = 12,
    this.isCircle = false,
    this.canEdit = false,
    this.onTap,
  });

  String? get _resolvedUrl {
    if (avatarUrl == null || avatarUrl!.isEmpty) return null;
    if (avatarUrl!.startsWith('http://') || avatarUrl!.startsWith('https://')) {
      return avatarUrl;
    }
    final cleanPath = avatarUrl!.replaceAll('\\', '/');
    return '${ApiConstants.baseHost}${cleanPath.startsWith('/') ? '' : '/'}$cleanPath';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveBorderRadius = isCircle ? BorderRadius.circular(size / 2) : BorderRadius.circular(borderRadius);
    final initial = (name != null && name!.trim().isNotEmpty) ? name!.trim()[0].toUpperCase() : 'U';
    final fullUrl = _resolvedUrl;

    Widget avatarContent;

    if (fullUrl != null && fullUrl.isNotEmpty) {
      avatarContent = Image.network(
        fullUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackInitial(initial),
      );
    } else {
      avatarContent = _buildFallbackInitial(initial);
    }

    Widget widget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: avatarContent,
      ),
    );

    if (canEdit) {
      widget = Stack(
        clipBehavior: Clip.none,
        children: [
          widget,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        if (canEdit) {
          AvatarUploadHelper.pickAndUpload(
            context,
            ref,
            targetUserId: userId,
            targetUserName: name,
          );
        } else if (onTap != null) {
          onTap!();
        }
      },
      child: widget,
    );
  }

  Widget _buildFallbackInitial(String initial) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(
          fontSize: size * 0.44,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
