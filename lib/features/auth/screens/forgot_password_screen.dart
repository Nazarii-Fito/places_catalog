import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';

/// Temporary placeholder — replaced by the real layout in Phase 3.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          AppStrings.resetPasswordTitle,
          style: AppTextStyles.largeTitle,
        ),
      ),
    );
  }
}
