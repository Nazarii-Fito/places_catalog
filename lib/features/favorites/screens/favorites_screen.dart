import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';

/// Temporary placeholder — replaced by the real layout in Phase 3.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(AppStrings.favoritesTitle, style: AppTextStyles.largeTitle),
      ),
    );
  }
}
