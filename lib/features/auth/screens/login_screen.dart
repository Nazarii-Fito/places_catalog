import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';

/// Temporary placeholder — replaced by the real layout in Phase 3.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onTap: () =>
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
          child: const Text(AppStrings.logIn, style: AppTextStyles.largeTitle),
        ),
      ),
    );
  }
}
