import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_logo.dart';

/// Brand block of the auth screens: icon, large title, subtitle and the
/// soft blue glow behind the icon (Figma "Subtle decorative ambient
/// element").
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = const AppLogo.large(),
  });

  final String title;

  /// Either a plain [String] or rich text via [InlineSpan].
  final InlineSpan subtitle;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        const Positioned(top: -40, child: _AmbientGlow()),
        Column(
          children: [
            icon,
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.largeTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2.875),
            // Line breaks come from the string (as in Figma); the width cap
            // only guards long translations.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text.rich(
                subtitle,
                style: AppTextStyles.authSubtitle,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 192 pt circle of #D8E2FF @ 30 % blurred by 32 (CSS blur = sigma).
class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: const SizedBox.square(
          dimension: 192,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.ambientGlow,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
