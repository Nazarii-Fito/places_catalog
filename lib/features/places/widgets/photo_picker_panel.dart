import 'package:flutter/widgets.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/pressable_opacity.dart';

/// "Add Photos" panel with removable thumbnails and an "N left" tile.
class PhotoPickerPanel extends StatelessWidget {
  const PhotoPickerPanel({
    super.key,
    required this.photos,
    required this.maxPhotos,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photos;
  final int maxPhotos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final int left = maxPhotos - photos.length;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: const BoxDecoration(
        color: AppColors.primaryContainerSoft,
        borderRadius: AppRadii.mdAll,
      ),
      child: Column(
        children: [
          PressableOpacity(
            onTap: left > 0 ? onAdd : null,
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.subtle,
                  ),
                  child: const AppSvgIcon(AppAssets.iconCameraAdd),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.addPhotos,
                  style: AppTextStyles.socialLabel.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            AppStrings.addPhotosHint,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              spacing: AppSpacing.sm,
              children: [
                for (final (int i, String photo) in photos.indexed)
                  _Thumb(asset: photo, onRemove: () => onRemove(i)),
                if (left > 0) _AddMoreTile(left: left, onTap: onAdd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.asset, required this.onRemove});

  final String asset;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: AppRadii.smAll,
        boxShadow: AppShadows.group,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(asset, fit: BoxFit.cover),
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: Semantics(
              button: true,
              label: AppStrings.removePhoto,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.photoRemoveBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const AppSvgIcon(AppAssets.iconCloseTiny),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMoreTile extends StatelessWidget {
  const _AddMoreTile({required this.left, required this.onTap});

  final int left;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableOpacity(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: AppRadii.smAll,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppSvgIcon(
              AppAssets.iconPlus,
              width: 11.667,
              height: 11.667,
              color: AppColors.textSecondary,
            ),
            Text(
              '$left${AppStrings.photosLeftSuffix}',
              style: AppTextStyles.tabLabel.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
