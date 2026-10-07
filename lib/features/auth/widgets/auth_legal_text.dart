import 'package:flutter/widgets.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// "By continuing, you agree to our Terms of Service and Privacy Policy."
///
/// Built from [TextSpan]s; links are only coloured (no legal pages in
/// Lab 3), so no gesture recognizers are attached.
class AuthLegalText extends StatelessWidget {
  const AuthLegalText({super.key, required this.prefix});

  final String prefix;

  static const TextStyle _link = TextStyle(color: AppColors.primary);

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: prefix,
        children: const [
          TextSpan(text: AppStrings.termsOfService, style: _link),
          TextSpan(text: AppStrings.and),
          TextSpan(text: AppStrings.privacyPolicy, style: _link),
          TextSpan(text: AppStrings.period),
        ],
      ),
      style: AppTextStyles.legal,
      textAlign: TextAlign.center,
    );
  }
}
