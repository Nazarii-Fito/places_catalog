import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Round profile picture loaded from an HTTPS link ([imageUrl], e.g. the
/// Firebase `photoURL`). Shows [initials] when there is no link or the
/// image fails to load — null safety makes that fallback explicit.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.imageUrl,
    required this.initials,
    this.size = AppSizes.avatar,
  });

  final String? imageUrl;
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String? url = imageUrl;
    final Widget placeholder = Center(
      child: Text(
        initials,
        style: AppTextStyles.largeTitle.copyWith(color: AppColors.primary),
      ),
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        shape: BoxShape.circle,
        boxShadow: AppShadows.elevated,
      ),
      child: url == null || url.isEmpty
          ? placeholder
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}
