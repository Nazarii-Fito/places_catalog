import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/add_tag_dialog.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/nav_back_button.dart';
import '../../../core/widgets/pressable_opacity.dart';
import '../../../data/models/place.dart';
import '../../../data/models/place_category.dart';
import '../../../data/models/review.dart';
import '../bloc/places_bloc.dart';
import '../bloc/update_place_bloc.dart';
import '../place_details_args.dart';
import '../widgets/details_hero.dart';
import '../widgets/details_sections.dart';
import '../widgets/rating_summary_card.dart';

/// Place details (FR5, FR7): photo, ratings, notes, tags, map and delete.
///
/// Only the place id arrives ([PlaceDetailsArgs]); the place itself is read
/// from `PlacesBloc` with a `BlocSelector`, so the screen always shows the
/// latest data (a heart tapped here is the same heart as on Home) and
/// every action is an event sent to the bloc.
class PlaceDetailsScreen extends StatelessWidget {
  const PlaceDetailsScreen({super.key, required this.args});

  final PlaceDetailsArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PlacesBloc, PlacesState, Place?>(
      selector: (PlacesState state) => state.byId(args.placeId),
      builder: (BuildContext context, Place? place) {
        // `null` for one frame after Delete, before the route is popped.
        if (place == null) return const Scaffold();
        return _PlaceDetailsView(place: place);
      },
    );
  }
}

class _PlaceDetailsView extends StatelessWidget {
  const _PlaceDetailsView({required this.place});

  final Place place;

  PlacesBloc _bloc(BuildContext context) => context.read<PlacesBloc>();

  Future<void> _confirmDelete(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final PlacesBloc bloc = _bloc(context);
    final bool confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deleteDialogTitle,
      message: AppStrings.deleteDialogMessage,
      confirmLabel: AppStrings.delete,
      isDestructive: true,
    );
    if (!confirmed) return;
    bloc.add(PlaceDeleted(place.id));
    navigator.pop();
  }

  /// Saves an edited review through the same bloc as the full form, so the
  /// catalog has exactly one write path.
  void _updateReview(BuildContext context, Review review) {
    context.read<UpdatePlaceBloc>().add(
      UpdatePlaceSubmitted(
        original: place,
        draft: place.copyWith(review: review),
        origin: UpdateOrigin.inline,
      ),
    );
  }

  void _saveNote(BuildContext context, Review review, String text) =>
      _updateReview(
        context,
        review.copyWith(textNote: text, updatedAt: DateTime.now()),
      );

  Future<void> _addTag(BuildContext context, Review review) async {
    final String? tag = await showAddTagDialog(context);
    if (tag == null || review.tags.contains(tag) || !context.mounted) return;
    _updateReview(context, review.copyWith(tags: [...review.tags, tag]));
  }

  void _removeTag(BuildContext context, Review review, String tag) =>
      _updateReview(
        context,
        review.copyWith(
          tags: review.tags.where((String t) => t != tag).toList(),
        ),
      );

  /// Opens the shared form in edit mode; it saves through `UpdatePlaceBloc`.
  void _editPlace(BuildContext context) =>
      Navigator.of(context).pushNamed(AppRoutes.editPlace, arguments: place);

  // Opening Apple Maps needs a platform plugin (url_launcher), which is out
  // of Lab 3 scope; the link is shown as designed but inert.
  void _openMaps() {}

  @override
  Widget build(BuildContext context) {
    final Review? review = place.review;
    // A failed notes/tags save is reported here (the form reports its own).
    return BlocListener<UpdatePlaceBloc, UpdatePlaceState>(
      listenWhen: (before, now) =>
          now is PlaceUpdateErrorState && now.origin == UpdateOrigin.inline,
      listener: (BuildContext context, UpdatePlaceState state) {
        AppConfirmDialog.show(
          context,
          title: AppStrings.placesSaveErrorTitle,
          message: (state as PlaceUpdateErrorState).message,
          confirmLabel: AppStrings.ok,
          cancelLabel: null,
        );
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppNavHeader(
          leading: const NavBackButton(),
          title: AppStrings.placeDetails,
          trailing: Semantics(
            button: true,
            label: AppStrings.editPlaceLabel,
            child: PressableOpacity(
              onTap: () => _editPlace(context),
              child: const SizedBox.square(
                dimension: AppSpacing.minTapTarget,
                child: Center(
                  child: AppSvgIcon(
                    AppAssets.iconPencil,
                    width: 16,
                    height: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Builder(
          builder: (BuildContext context) {
            final EdgeInsets insets = MediaQuery.paddingOf(context);
            return ListView(
              padding: EdgeInsets.only(top: insets.top),
              children: [
                DetailsHero(
                  image: place.heroImage,
                  photosCount: place.photosCount,
                  isFavorite: place.isFavorite,
                  onToggleFavorite: () =>
                      _bloc(context).add(PlaceFavoriteToggled(place.id)),
                ),
                // The sheet overlaps the photo by 24 pt, like in Figma.
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: _DetailsSheet(
                    bottomInset: insets.bottom,
                    children: [
                      _TitleBlock(place: place),
                      if (review != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        RatingSummaryCard(review: review),
                        const SizedBox(height: AppSpacing.xl),
                        NotesSection(
                          note: review.textNote,
                          updatedAt: review.updatedAt,
                          onSave: (String text) =>
                              _saveNote(context, review, text),
                        ),
                        const SizedBox(height: AppSpacing.l),
                        TagsSection(
                          tags: review.tags,
                          onAddTag: () => _addTag(context, review),
                          onRemoveTag: (String tag) =>
                              _removeTag(context, review, tag),
                        ),
                      ],
                      const SizedBox(height: 28),
                      LocationSection(
                        label: _shortAddress(place.address),
                        onOpenMaps: _openMaps,
                      ),
                      const SizedBox(height: 28),
                      _DeleteButton(onPressed: () => _confirmDelete(context)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// "424 Broome St, SoHo, Manhattan" → "424 Broome St, SoHo".
  static String _shortAddress(String address) =>
      address.split(', ').take(2).join(', ');
}

class _DetailsSheet extends StatelessWidget {
  const _DetailsSheet({required this.children, required this.bottomInset});

  final List<Widget> children;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + bottomInset - 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppShadows.sheet,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: SizedBox(
              width: 40,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.handle,
                  borderRadius: AppRadii.pillAll,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          ...children,
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.place});

  final Place place;

  static const Map<PlaceCategory, String> _categoryIcons = {
    PlaceCategory.cafe: AppAssets.iconCup,
    PlaceCategory.bakery: AppAssets.iconCup,
    PlaceCategory.museum: AppAssets.iconMuseum,
  };

  @override
  Widget build(BuildContext context) {
    final String area = place.address.split(', ').skip(1).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(place.name, style: AppTextStyles.placeTitle),
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            _InfoChip(
              icon: AppSvgIcon(
                _categoryIcons[place.category] ?? AppAssets.iconForkKnife,
                height: 11.25,
              ),
              text: AppStrings.categorySingular[place.category] ?? '',
            ),
            if (area.isNotEmpty)
              _InfoChip(icon: const AppSvgIcon(AppAssets.iconPin), text: area),
          ],
        ),
        const SizedBox(height: AppSpacing.ml),
        Row(
          spacing: AppSpacing.sm,
          children: [
            const AppSvgIcon(AppAssets.iconCalendarCheck),
            Text(
              AppStrings.visitedOnPrefix + formatLongDate(place.visitDate),
              style: AppTextStyles.footnoteMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          icon,
          Text(
            text,
            style: AppTextStyles.footnoteMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: PressableOpacity(
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l,
            vertical: 13,
          ),
          decoration: const BoxDecoration(
            color: AppColors.destructiveContainer,
            borderRadius: AppRadii.lgAll,
            boxShadow: AppShadows.group,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              const AppSvgIcon(AppAssets.iconTrash),
              Text(
                AppStrings.deletePlace,
                style: AppTextStyles.headline.copyWith(
                  color: AppColors.destructive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
