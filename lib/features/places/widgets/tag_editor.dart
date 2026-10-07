import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_svg_icon.dart';

/// Removable hashtag chips plus an "Add tag..." input.
class TagEditor extends StatelessWidget {
  const TagEditor({
    super.key,
    required this.tags,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> tags;
  final TextEditingController controller;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.mdAll,
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: tags
                .map(
                  (String tag) =>
                      _TagChip(text: tag, onRemove: () => onRemove(tag)),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          const SizedBox(
            height: 1,
            child: ColoredBox(color: AppColors.tagDivider),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const AppSvgIcon(AppAssets.iconTagAdd),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: AppTextStyles.caption,
                  textInputAction: TextInputAction.done,
                  onSubmitted: onAdd,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration.collapsed(
                    hintText: AppStrings.addTagHint,
                    hintStyle: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text, required this.onRemove});

  final String text;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 10, 4),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          Text(text, style: AppTextStyles.captionMedium),
          GestureDetector(
            onTap: onRemove,
            child: const AppSvgIcon(AppAssets.iconTagRemove),
          ),
        ],
      ),
    );
  }
}
