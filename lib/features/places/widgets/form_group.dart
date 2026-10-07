import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// UPPERCASE group title with an optional note on the right
/// ("EXPERIENCE RATINGS · 4.7 avg") above its [child].
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Widget? note = trailing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            0,
            AppSpacing.xs,
            AppSpacing.s,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: AppTextStyles.formSectionLabel,
                ),
              ),
              ?note,
            ],
          ),
        ),
        child,
      ],
    );
  }
}

/// White inset group of 48 pt rows separated by hairlines.
class FormGroup extends StatelessWidget {
  const FormGroup({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.mdAll,
        boxShadow: AppShadows.group,
      ),
      child: Column(
        children: [
          for (final (int index, Widget row) in rows.indexed) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.only(left: AppSpacing.l),
                child: SizedBox(
                  height: 0.5,
                  width: double.infinity,
                  child: ColoredBox(color: AppColors.surfaceContainerHigh),
                ),
              ),
            row,
          ],
        ],
      ),
    );
  }
}

/// One 48 pt row: [label] on the left, [trailing] control on the right.
///
/// By default the trailing control takes the free space (text inputs).
/// With [fixedTrailing] it keeps its own width and the label shrinks
/// instead — used by the star rows so they fit small screens.
class FormRow extends StatelessWidget {
  const FormRow({
    super.key,
    required this.label,
    required this.trailing,
    this.fixedTrailing = false,
  });

  final Widget label;
  final Widget trailing;
  final bool fixedTrailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        child: Row(
          children: fixedTrailing
              ? [
                  Expanded(child: label),
                  const SizedBox(width: AppSpacing.m),
                  trailing,
                ]
              : [
                  label,
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: trailing,
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}
