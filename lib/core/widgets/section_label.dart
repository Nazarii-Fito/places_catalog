import 'package:flutter/widgets.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// UPPERCASE caption above a grouped list ("ACCOUNT SETTINGS").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(text.toUpperCase(), style: AppTextStyles.sectionLabel),
    );
  }
}
