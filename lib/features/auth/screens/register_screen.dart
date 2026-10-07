import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';

/// Temporary placeholder — replaced by the real layout in Phase 3.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(AppStrings.createAccount, style: AppTextStyles.largeTitle),
      ),
    );
  }
}
