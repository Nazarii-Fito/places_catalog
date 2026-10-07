import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/app_text_link.dart';
import '../../../core/widgets/primary_button.dart';

/// Location picker (FR11) shown as a full-screen modal.
///
/// The map is a static picture from Figma (no map SDK). "Confirm" returns
/// the typed address to the caller with `Navigator.pop(result)`;
/// "Cancel" pops with `null`.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _queryController = TextEditingController(
    text: AppStrings.defaultMapQuery,
  );

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _confirm() {
    final String query = _queryController.text.trim();
    Navigator.of(context)
        .pop(query.isEmpty ? AppStrings.defaultLocation : query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Figma scales the map ~10 % beyond the screen edges.
          const Positioned(
            left: -19.5,
            right: -19.5,
            top: -42.2,
            bottom: -42.2,
            child: Image(
              image: AssetImage(AppAssets.mapManhattan),
              fit: BoxFit.cover,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.scrim5,
                  AppColors.transparent,
                  AppColors.scrim10,
                ],
              ),
            ),
          ),
          const Align(alignment: Alignment(0, -0.06), child: _DropPin()),
          SafeArea(
            minimum: const EdgeInsets.only(bottom: AppSpacing.l),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  _SearchBar(controller: _queryController),
                  const Spacer(),
                  _LocationCard(onConfirm: _confirm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      color: AppColors.glass85,
      radius: AppRadii.lg,
      blur: 12,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.ml,
        vertical: 10,
      ),
      child: Row(
        spacing: AppSpacing.m,
        children: [
          AppTextLink(
            label: AppStrings.cancel,
            style: AppTextStyles.body,
            horizontalPadding: AppSpacing.xs,
            onTap: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: AppColors.mapSearchBackground,
                borderRadius: AppRadii.mdAll,
              ),
              child: Row(
                spacing: AppSpacing.sm,
                children: [
                  const AppSvgIcon(AppAssets.iconSearch),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: AppTextStyles.mapSearch,
                      textInputAction: TextInputAction.search,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration.collapsed(
                        hintText: AppStrings.location,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: controller.clear,
                    child: Container(
                      width: 18.34,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: AppRadii.pillAll,
                      ),
                      child: const AppSvgIcon(AppAssets.iconCloseSmall),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        boxShadow: AppShadows.floating,
      ),
      child: _Glass(
        color: AppColors.glass95,
        radius: 24,
        blur: 20,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.l,
          children: [
            const Center(
              child: SizedBox(
                width: 36,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: AppRadii.pillAll,
                  ),
                ),
              ),
            ),
            const _PickedPlaceInfo(),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: PrimaryButton(
                label: AppStrings.confirmLocation,
                icon: const AppSvgIcon(AppAssets.iconCheckCircle),
                onPressed: onConfirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickedPlaceInfo extends StatelessWidget {
  const _PickedPlaceInfo();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.ml,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxs),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: AppRadii.lgAll,
            ),
            child: const AppSvgIcon(AppAssets.iconLocationArrow),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xxs,
            children: [
              const Text(
                AppStrings.pickedPlaceTitle,
                style: AppTextStyles.headline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                AppStrings.pickedPlaceAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subheadline.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Row(
                  spacing: AppSpacing.xs,
                  children: [
                    const AppSvgIcon(AppAssets.iconCompass),
                    Text(
                      AppStrings.pickedCoordinates,
                      style: AppTextStyles.footnote.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Red map pin with its ground shadow and anchor dot.
class _DropPin extends StatelessWidget {
  const _DropPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppSvgIcon(AppAssets.iconMapPin),
        const SizedBox(height: AppSpacing.xxs),
        SizedBox(
          width: 32,
          height: 12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 0.75, sigmaY: 0.75),
                child: const SizedBox(
                  width: 20,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.scrim30,
                      borderRadius: AppRadii.pillAll,
                    ),
                  ),
                ),
              ),
              const SizedBox.square(
                dimension: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.destructive,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Frosted panel: clip + backdrop blur + translucent fill.
class _Glass extends StatelessWidget {
  const _Glass({
    required this.color,
    required this.radius,
    required this.blur,
    required this.padding,
    required this.child,
  });

  final Color color;
  final double radius;
  final double blur;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(color: color, padding: padding, child: child),
      ),
    );
  }
}
