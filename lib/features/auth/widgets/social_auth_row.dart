import 'package:flutter/widgets.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/social_auth_button.dart';

/// Apple + Google buttons side by side (equal widths, 12 pt gap).
class SocialAuthRow extends StatelessWidget {
  const SocialAuthRow({super.key, required this.onProviderSelected});

  final ValueChanged<SocialProvider> onProviderSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SocialAuthButton(
            provider: SocialProvider.apple,
            onPressed: () => onProviderSelected(SocialProvider.apple),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: SocialAuthButton(
            provider: SocialProvider.google,
            onPressed: () => onProviderSelected(SocialProvider.google),
          ),
        ),
      ],
    );
  }
}
