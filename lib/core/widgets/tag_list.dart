import 'package:flutter/widgets.dart';

import '../constants/app_assets.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_svg_icon.dart';
import 'pressable_opacity.dart';

/// The single tag control of the app (Add Place and Place Details):
/// wrapping hashtag chips with a remove "×" and a "+ Add Tag" pill.
///
/// Stateless — the list lives in the parent screen; [onAdd] usually opens
/// `showAddTagDialog`, [onRemove] deletes one tag.
class TagList extends StatelessWidget {
  const TagList({
    super.key,
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> tags;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...tags.map(
          (String tag) => _TagChip(text: tag, onRemove: () => onRemove(tag)),
        ),
        _AddTagButton(onTap: onAdd),
      ],
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
      padding: const EdgeInsets.only(left: 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: AppTextStyles.captionMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
          Semantics(
            button: true,
            label: '${AppStrings.removeTag} $text',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              // Wider than the 8 pt glyph so the "×" is easy to hit.
              child: const Padding(
                padding: EdgeInsets.fromLTRB(6, 8, 10, 8),
                child: AppSvgIcon(AppAssets.iconTagRemove),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTagButton extends StatelessWidget {
  const _AddTagButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: PressableOpacity(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.sm,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: AppRadii.pillAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.xs,
            children: [
              const AppSvgIcon(
                AppAssets.iconPlus,
                width: 7.583,
                height: 7.583,
                color: AppColors.textSecondary,
              ),
              Text(
                AppStrings.addTag,
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
