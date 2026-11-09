# Фрагменти коду для звіту ЛР №5

Усі фрагменти згенеровано з актуальних джерел репозиторію. Код, ідентифікатори та коментарі в ньому англійською (так задумано), пояснення — українською.

## 2.1 Екран зі списком: Home на `CustomScrollView` + слівери

Заголовок, пошук, чипи й підсумок — `SliverToBoxAdapter`; картки — `SliverList.separated`, які створюються ліниво. Стани завантаження, помилки й порожнього результату — окремі слівери. Дані й налаштування читаються з `PlacesBloc` та `CatalogViewCubit`.

Файл: `lib/features/home/screens/home_screen.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes/app_routes.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/place_card.dart';
import '../../../core/widgets/search_field.dart';
import '../../../data/models/place.dart';
import '../../../core/widgets/error_state.dart';
import '../../places/bloc/places_bloc.dart';
import '../../places/place_details_args.dart';
import '../bloc/catalog_view_cubit.dart';
import '../home_filter.dart';
import '../widgets/catalog_summary_strip.dart';
import '../widgets/home_title_row.dart';

/// Home tab — "My Places" catalog (FR3, FR9).
///
/// * The catalog comes from `PlacesBloc` (loading / failure / loaded).
/// * Filter, sort and search come from `CatalogViewCubit`; the visible
///   list is the pure function `visiblePlaces(places, view)`.
/// * Only the search `TextEditingController` is ephemeral and stays in
///   this `State`.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addPlace() async {
    final PlacesBloc bloc = context.read<PlacesBloc>();
    final Object? result = await Navigator.of(context)
        .pushNamed(AppRoutes.addPlace);
    if (result is Place) bloc.add(PlaceCreated(result));
  }

  void _openPlace(Place place) {
    context.read<PlacesBloc>().add(PlaceOpened(place.id));
    Navigator.of(context).pushNamed(
      AppRoutes.placeDetails,
      arguments: PlaceDetailsArgs(placeId: place.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CatalogViewCubit view = context.read<CatalogViewCubit>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppNavHeader(title: AppStrings.tabHome),
      // Builder: read the insets *inside* this Scaffold — they include the
      // translucent header (top) and the tab bar of MainShell (bottom).
      body: Builder(
        builder: (BuildContext context) {
          final EdgeInsets insets = MediaQuery.paddingOf(context);
          // CustomScrollView + slivers: the header blocks are single boxes
          // (SliverToBoxAdapter) and the cards are built lazily by
          // SliverList, so a long catalog only builds what is on screen.
          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(top: insets.top + AppSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _Padded(child: HomeTitleRow(onAdd: _addPlace)),
                      const SizedBox(height: AppSpacing.m),
                      _Padded(
                        child: SearchField(
                          controller: _searchController,
                          hintText: AppStrings.searchHint,
                          onChanged: view.setQuery,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      BlocBuilder<CatalogViewCubit, CatalogViewState>(
                        buildWhen: (a, b) => a.filter != b.filter,
                        builder: (BuildContext context, CatalogViewState s) =>
                            SizedBox(
                              height: 40,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.screen,
                                ),
                                itemCount: HomeFilter.values.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: AppSpacing.sm),
                                itemBuilder: (BuildContext context, int index) {
                                  final HomeFilter filter =
                                      HomeFilter.values[index];
                                  return CategoryChip(
                                    label: filter.label,
                                    selected: filter == s.filter,
                                    onTap: () => view.setFilter(filter),
                                  );
                                },
                              ),
                            ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      _Padded(
                        child: BlocBuilder<PlacesBloc, PlacesState>(
                          builder: (BuildContext context, PlacesState p) =>
                              BlocBuilder<CatalogViewCubit, CatalogViewState>(
                                builder:
                                    (
                                      BuildContext context,
                                      CatalogViewState s,
                                    ) => CatalogSummaryStrip(
                                      count: visiblePlaces(p.places, s).length,
                                      sort: s.sort,
                                      onSortSelected: view.setSort,
                                    ),
                              ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                    ],
                  ),
                ),
              ),
              ..._body(context),
              SliverToBoxAdapter(child: SizedBox(height: insets.bottom + 20)),
            ],
          );
        },
      ),
    );
  }

  /// The part below the filters. Built from both blocs; a `BlocBuilder`
  /// around a *sliver* is not possible inside a plain list, so each state
  /// is wrapped in a [SliverToBoxAdapter] or [SliverMainAxisGroup].
  List<Widget> _body(BuildContext context) {
    return [
      BlocBuilder<PlacesBloc, PlacesState>(
        builder: (BuildContext context, PlacesState places) {
          switch (places.status) {
            case PlacesStatus.initial:
            case PlacesStatus.loading:
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 64),
                  child: Center(child: CupertinoActivityIndicator(radius: 14)),
                ),
              );
            case PlacesStatus.failure:
              return SliverToBoxAdapter(
                child: ErrorState(
                  message: places.errorMessage ?? AppStrings.errorUnknown,
                  onRetry: () => context.read<PlacesBloc>().add(
                    const PlacesLoadRequested(),
                  ),
                ),
              );
            case PlacesStatus.loaded:
              return BlocBuilder<CatalogViewCubit, CatalogViewState>(
                builder: (BuildContext context, CatalogViewState view) {
                  // A new list is filtered and sorted; the bloc's list is
                  // never touched.
                  final List<Place> visible = visiblePlaces(
                    places.places,
                    view,
                  );
                  if (visible.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: EmptyState(
                        title: AppStrings.emptyTitle,
                        subtitle: AppStrings.emptySubtitle,
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    sliver: SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.ml),
                      itemBuilder: (BuildContext context, int index) {
                        final Place place = visible[index];
                        return PlaceCard(
                          // A stable key keeps each card's state with its
                          // place when the list is re-sorted or filtered.
                          key: ValueKey<String>(place.id),
                          place: place,
                          onTap: () => _openPlace(place),
                          onFavoriteToggle: () => context
                              .read<PlacesBloc>()
                              .add(PlaceFavoriteToggled(place.id)),
                        );
                      },
                    ),
                  );
                },
              );
          }
        },
      ),
    ];
  }
}

class _Padded extends StatelessWidget {
  const _Padded({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: child,
    );
  }
}
```

## 2.2 Екран перегляду та екран редагування об'єкта

### Place Details (перегляд)

Файл: `lib/features/places/screens/place_details_screen.dart`

Заклад читається з `PlacesBloc` через `BlocSelector` за `id`; усі дії — події блока.

```dart
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

  /// Replaces the review with an edited copy.
  void _updateReview(BuildContext context, Review review) =>
      _bloc(context).add(PlaceUpdated(place.copyWith(review: review)));

  void _saveNote(BuildContext context, Review review, String text) =>
      _updateReview(
        context,
        review.copyWith(textNote: text, updatedAt: DateTime.now()),
      );

  Future<void> _addTag(BuildContext context, Review review) async {
    final PlacesBloc bloc = _bloc(context);
    final String? tag = await showAddTagDialog(context);
    if (tag == null || review.tags.contains(tag)) return;
    bloc.add(
      PlaceUpdated(
        place.copyWith(review: review.copyWith(tags: [...review.tags, tag])),
      ),
    );
  }

  void _removeTag(BuildContext context, Review review, String tag) =>
      _updateReview(
        context,
        review.copyWith(
          tags: review.tags.where((String t) => t != tag).toList(),
        ),
      );

  /// Opens the shared form in edit mode and stores the result it returns.
  Future<void> _editPlace(BuildContext context) async {
    final PlacesBloc bloc = _bloc(context);
    final Object? result = await Navigator.of(context)
        .pushNamed(AppRoutes.editPlace, arguments: place);
    if (result is Place) bloc.add(PlaceUpdated(result));
  }

  // Opening Apple Maps needs a platform plugin (url_launcher), which is out
  // of Lab 3 scope; the link is shown as designed but inert.
  void _openMaps() {}

  @override
  Widget build(BuildContext context) {
    final Review? review = place.review;
    return Scaffold(
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
```

### PlaceFormScreen (створення й редагування, `Form` + `GlobalKey`)

Файл: `lib/features/places/screens/place_form_screen.dart`

Один екран для двох режимів: `initial == null` — створення. Валідація: назва 2–50 символів, локація обов'язкова.

```dart
import 'package:flutter/material.dart';

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
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/nav_back_button.dart';
import '../../../core/widgets/pressable_opacity.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/tag_list.dart';
import '../../../app/dev_launch_options.dart';
import '../../../core/validation/validators.dart';
import '../../../data/models/place.dart';
import '../../../data/models/place_category.dart';
import '../../../data/models/place_photo.dart';
import '../../../data/models/review.dart';
import '../widgets/form_group.dart';
import '../widgets/photo_picker_panel.dart';
import '../widgets/star_rating_input.dart';
import 'add_place_pickers.dart';

/// Create (`initial == null`) or edit (`initial != null`) a place — FR4, FR8.
///
/// One screen for both modes keeps the layout identical and removes the
/// duplicated form. UI state (text controllers, picked photos, ratings) is
/// *ephemeral* and stays in this `State`; the finished [Place] is returned
/// to the caller through `Navigator.pop`, so the form never needs to know
/// where or how the catalog is stored.
///
/// Validation is a [Form] + [GlobalKey]: name (2–50 chars) and location are
/// required. Errors appear only after the first "Save" tap, then follow
/// every change.
class PlaceFormScreen extends StatefulWidget {
  const PlaceFormScreen({super.key, this.initial});

  /// The place being edited, or `null` to create a new one.
  final Place? initial;

  @override
  State<PlaceFormScreen> createState() => _PlaceFormScreenState();
}

class _PlaceFormScreenState extends State<PlaceFormScreen> {
  static const int _maxPhotos = 5;
  static const List<String> _demoPhotos = [
    AppAssets.photoCoffee,
    AppAssets.photoPasta,
    AppAssets.photoStorefront,
  ];

  /// Filled in for new places in screenshot mode only (`DEMO_FORM`).
  static const bool _demo = DevLaunchOptions.demoForm;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late List<String> _photos;
  late PlaceCategory _category;
  late String _location;
  late DateTime _visitDate;
  late final Map<String, int> _ratings;
  late List<String> _tags;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final Place? place = widget.initial;
    final Review? review = place?.review;
    _nameController = TextEditingController(
      text: place?.name ?? (_demo ? AppStrings.placeNameHint : ''),
    );
    _notesController = TextEditingController(
      text: review?.textNote ?? (_demo ? AppStrings.defaultNote : ''),
    );
    _photos = place != null
        ? [for (final PlacePhoto p in place.photos) p.imageAsset]
        : (_demo ? List.of(_demoPhotos) : <String>[]);
    _category = place?.category ?? PlaceCategory.cafe;
    _location = place?.address ?? (_demo ? AppStrings.defaultLocation : '');
    _visitDate =
        place?.visitDate ?? (_demo ? DateTime(2026, 9, 24) : DateTime.now());
    // A review needs a rating of at least 1, so every criterion starts at a
    // neutral 3 stars (the user can change it) instead of "unrated".
    _ratings = {
      AppStrings.ratingFood: _stars(review?.foodRating, _demo ? 5 : 3),
      AppStrings.ratingService: _stars(review?.serviceRating, _demo ? 4 : 3),
      AppStrings.ratingAtmosphere: _stars(
        review?.atmosphereRating,
        _demo ? 5 : 3,
      ),
    };
    _tags = review != null
        ? List.of(review.tags)
        : (_demo
              ? ['#Espresso', '#Pastries', '#QuietWork', '#NaturalLight']
              : <String>[]);
  }

  static int _stars(double? stored, int fallback) =>
      stored == null ? fallback : stored.round().clamp(1, 5);

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _averageRating =>
      _ratings.values.reduce((int a, int b) => a + b) / _ratings.length;

  void _addPhoto() => setState(() {
    _photos = [..._photos, _demoPhotos[_photos.length % _demoPhotos.length]];
  });

  void _removePhoto(int index) => setState(() {
    _photos = [..._photos]..removeAt(index);
  });

  /// Builds the result from the form. For an edit the identity (id,
  /// favourite flag, coordinates) is kept; for a new place they are created.
  Place _buildPlace() {
    final Place? old = widget.initial;
    final Map<String, PlacePhoto> oldPhotos = {
      for (final PlacePhoto p in old?.photos ?? const <PlacePhoto>[])
        p.imageAsset: p,
    };
    final List<PlacePhoto> photos = [
      for (final String asset in _photos)
        oldPhotos[asset] ?? PlacePhoto(imageAsset: asset, fileSizeBytes: 0),
    ];
    final double food = _ratings[AppStrings.ratingFood]!.toDouble();
    final double service = _ratings[AppStrings.ratingService]!.toDouble();
    final double atmosphere = _ratings[AppStrings.ratingAtmosphere]!.toDouble();
    final Review review = Review(
      overallRating: _averageRating,
      foodRating: food,
      serviceRating: service,
      atmosphereRating: atmosphere,
      textNote: _notesController.text.trim(),
      tags: _tags,
      updatedAt: DateTime.now(),
    );
    final bool sameCategory = old != null && old.category == _category;
    return Place(
      // Local id: no backend yet, microseconds are unique enough per device.
      id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      category: _category,
      subtitle: sameCategory
          ? old.subtitle
          : (AppStrings.categorySingular[_category] ?? _category.name),
      address: _location,
      visitDate: _visitDate,
      coverImage: photos.isNotEmpty
          ? photos.first.imageAsset
          : (old?.coverImage ?? AppAssets.photoStorefront),
      review: review,
      isFavorite: old?.isFavorite ?? false,
      latitude: old?.latitude,
      longitude: old?.longitude,
      photos: photos,
    );
  }

  void _revalidate() {
    if (_submitted) _formKey.currentState?.validate();
  }

  void _save() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_buildPlace());
  }

  Future<void> _pickCategory() async {
    final PlaceCategory? picked = await showCategoryPicker(context, _category);
    if (picked != null) setState(() => _category = picked);
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showVisitDatePicker(context, _visitDate);
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _pickLocation() async {
    final Object? result = await Navigator.of(context)
        .pushNamed(AppRoutes.locationPicker);
    if (result is String) {
      setState(() => _location = result);
      _revalidate();
    }
  }

  Future<void> _addTag() async {
    final String? tag = await showAddTagDialog(context);
    if (tag == null || _tags.contains(tag)) return;
    setState(() => _tags = [..._tags, tag]);
  }

  void _removeTag(String tag) =>
      setState(() => _tags = _tags.where((String t) => t != tag).toList());

  @override
  Widget build(BuildContext context) {
    final Map<String, String> ratingIcons = {
      AppStrings.ratingFood: AppAssets.iconRatingFood,
      AppStrings.ratingService: AppAssets.iconRatingService,
      AppStrings.ratingAtmosphere: AppAssets.iconRatingAtmosphere,
    };
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppNavHeader(
        leading: const NavBackButton(),
        title: _isEditing
            ? AppStrings.editPlaceTitle
            : AppStrings.addPlaceTitle,
      ),
      body: Builder(
        builder: (BuildContext context) {
          final EdgeInsets insets = MediaQuery.paddingOf(context);
          return Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screen,
                insets.top + 7,
                AppSpacing.screen,
                insets.bottom + AppSpacing.xxl,
              ),
              children: [
                PhotoPickerPanel(
                  photos: _photos,
                  maxPhotos: _maxPhotos,
                  onAdd: _addPhoto,
                  onRemove: _removePhoto,
                ),
                const SizedBox(height: AppSpacing.l),
                FormSection(
                  title: AppStrings.venueInfo,
                  child: FormGroup(
                    rows: [
                      FormRow(
                        label: const _RowLabel(AppStrings.placeName),
                        trailing: TextField(
                          controller: _nameController,
                          onChanged: (_) => _revalidate(),
                          textAlign: TextAlign.right,
                          style: AppTextStyles.body,
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          decoration: InputDecoration.collapsed(
                            hintText: AppStrings.placeNameHint,
                            // A hint must look like a hint, not like a value.
                            hintStyle: AppTextStyles.body.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                      FormRow(
                        label: const _RowLabel(AppStrings.category),
                        trailing: _ValueButton(
                          text: AppStrings.categorySingular[_category] ?? '',
                          icon: AppAssets.iconChevronUpDown,
                          onTap: _pickCategory,
                        ),
                      ),
                      FormRow(
                        label: const _RowLabel(AppStrings.location),
                        trailing: _ValueButton(
                          text: _location.isEmpty
                              ? AppStrings.locationHint
                              : _location,
                          isPlaceholder: _location.isEmpty,
                          icon: AppAssets.iconMapPinned,
                          onTap: _pickLocation,
                        ),
                      ),
                      FormRow(
                        label: const _RowLabel(AppStrings.dateOfVisit),
                        trailing: _DatePill(date: _visitDate, onTap: _pickDate),
                      ),
                    ],
                  ),
                ),
                _FieldError(
                  validator: (_) => Validators.placeName(_nameController.text),
                ),
                _FieldError(validator: (_) => Validators.location(_location)),
                const SizedBox(height: AppSpacing.l),
                FormSection(
                  title: AppStrings.experienceRatings,
                  trailing: Text(
                    _averageRating.toStringAsFixed(1) + AppStrings.avgSuffix,
                    style: AppTextStyles.captionMedium.copyWith(
                      color: AppColors.cafeAccent,
                    ),
                  ),
                  child: FormGroup(
                    rows: _ratings.entries
                        .map(
                          (MapEntry<String, int> e) => FormRow(
                            fixedTrailing: true,
                            label: Row(
                              spacing: AppSpacing.sm,
                              children: [
                                AppSvgIcon(ratingIcons[e.key]!),
                                Flexible(child: _RowLabel(e.key)),
                              ],
                            ),
                            trailing: StarRatingInput(
                              value: e.value,
                              onChanged: (int v) =>
                                  setState(() => _ratings[e.key] = v),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                FormSection(
                  title: AppStrings.personalNotes,
                  trailing: const _SectionNote(AppStrings.privateToYou),
                  child: _NotesCard(
                    controller: _notesController,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                FormSection(
                  title: AppStrings.tags,
                  trailing: _SectionNote(
                    '${_tags.length}${AppStrings.tagsSuffix}',
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadii.mdAll,
                      boxShadow: AppShadows.subtle,
                    ),
                    child: TagList(
                      tags: _tags,
                      onAdd: _addTag,
                      onRemove: _removeTag,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.l + AppSpacing.sm),
                PrimaryButton(
                  label: _isEditing
                      ? AppStrings.saveChanges
                      : AppStrings.savePlaceRecord,
                  height: 48,
                  onPressed: _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Red message under the venue group; empty (zero height) while valid.
///
/// The rows of the group are custom controls, not text fields, so their
/// errors are shown by a dedicated [FormField] that takes part in
/// `FormState.validate()` like any other field.
class _FieldError extends StatelessWidget {
  const _FieldError({required this.validator});

  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: validator,
      builder: (FormFieldState<String> field) {
        final String? message = field.errorText;
        if (message == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            top: AppSpacing.s,
          ),
          child: Text(
            message,
            style: AppTextStyles.caption.copyWith(color: AppColors.destructive),
          ),
        );
      },
    );
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.body,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

class _SectionNote extends StatelessWidget {
  const _SectionNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.tabLabel.copyWith(color: AppColors.textTertiary),
  );
}

/// Grey value + small icon on the right of a row (Category, Location).
class _ValueButton extends StatelessWidget {
  const _ValueButton({
    required this.text,
    required this.icon,
    required this.onTap,
    this.isPlaceholder = false,
  });

  final String text;
  final String icon;

  /// Greys the text further when it is a hint, not a chosen value.
  final bool isPlaceholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableOpacity(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.s,
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subheadline.copyWith(
                color: isPlaceholder
                    ? AppColors.textTertiary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          AppSvgIcon(icon),
        ],
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableOpacity(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadii.smAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.s,
          children: [
            const AppSvgIcon(AppAssets.iconCalendar),
            Text(formatMediumDate(date), style: AppTextStyles.footnoteMedium),
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

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
          TextField(
            controller: controller,
            onChanged: onChanged,
            minLines: 4,
            maxLines: null,
            style: AppTextStyles.noteInput,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            decoration: const InputDecoration.collapsed(
              hintText: AppStrings.notesHint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${controller.text.length}${AppStrings.charsSuffix}',
            textAlign: TextAlign.right,
            style: AppTextStyles.tabLabel.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
```

## 3. Керування станом: BLoC / Cubit

### 3.1 `PlacesBloc` (3.3 списки, 3.4 створення / редагування / видалення)

### Події

Файл: `lib/features/places/bloc/places_event.dart`

```dart
part of 'places_bloc.dart';

/// Everything that can happen to the catalog. Each event is a plain
/// immutable message from the UI (or app code) to [PlacesBloc]: the UI
/// never edits the list itself, it only *describes what the user did*.
sealed class PlacesEvent extends Equatable {
  const PlacesEvent();

  @override
  List<Object?> get props => const [];
}

/// Load the catalog from the repository (first start and "Retry").
final class PlacesLoadRequested extends PlacesEvent {
  const PlacesLoadRequested();
}

/// A new place from the form.
final class PlaceCreated extends PlacesEvent {
  const PlaceCreated(this.place);

  final Place place;

  @override
  List<Object?> get props => [place];
}

/// The edited copy of an existing place (form, notes, tags).
final class PlaceUpdated extends PlacesEvent {
  const PlaceUpdated(this.place);

  final Place place;

  @override
  List<Object?> get props => [place];
}

final class PlaceDeleted extends PlacesEvent {
  const PlaceDeleted(this.placeId);

  final String placeId;

  @override
  List<Object?> get props => [placeId];
}

final class PlaceFavoriteToggled extends PlacesEvent {
  const PlaceFavoriteToggled(this.placeId);

  final String placeId;

  @override
  List<Object?> get props => [placeId];
}

/// A card was opened. Changes no data; it exists so the analytics call
/// lives in the bloc and not in a widget.
final class PlaceOpened extends PlacesEvent {
  const PlaceOpened(this.placeId);

  final String placeId;

  @override
  List<Object?> get props => [placeId];
}
```

### Стан

Файл: `lib/features/places/bloc/places_state.dart`

```dart
part of 'places_bloc.dart';

enum PlacesStatus { initial, loading, loaded, failure }

/// Immutable snapshot of the catalog for the UI.
///
/// [errorMessage] has two meanings, told apart by [status]: with `failure`
/// the list could not be loaded (full-screen error + Retry); with `loaded`
/// a later change could not be saved (the list is intact, an alert is
/// shown once).
final class PlacesState extends Equatable {
  const PlacesState({
    this.status = PlacesStatus.initial,
    this.places = const [],
    this.errorMessage,
  });

  final PlacesStatus status;
  final List<Place> places;
  final String? errorMessage;

  /// The place with [id], or `null` (e.g. right after it was deleted).
  Place? byId(String id) {
    for (final Place place in places) {
      if (place.id == id) return place;
    }
    return null;
  }

  PlacesState copyWith({
    PlacesStatus? status,
    List<Place>? places,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlacesState(
      status: status ?? this.status,
      places: places ?? this.places,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, places, errorMessage];
}
```

### Блок

Файл: `lib/features/places/bloc/places_bloc.dart`

```dart
// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/models/place.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/services/crash_reporter.dart';

part 'places_event.dart';
part 'places_state.dart';

/// Owns the catalog of one signed-in user (app state shared by Home,
/// Favorites, Details and Profile).
///
/// Cycle: the UI adds an [PlacesEvent] → the handler talks to the
/// [PlacesRepository] (disk) → `emit` publishes a *new* [PlacesState] →
/// `BlocBuilder`s rebuild. The list is never mutated in place, so
/// Equatable can tell that something changed.
///
/// One instance per uid: it is created with the user in `UserScope`, so
/// switching accounts drops this state and one user's catalog can never
/// leak to the next.
class PlacesBloc extends Bloc<PlacesEvent, PlacesState> {
  PlacesBloc({
    required this.uid,
    required PlacesRepository repository,
    required AnalyticsService analytics,
    required CrashReporter crashReporter,
  }) : _repository = repository,
       _analytics = analytics,
       _crashReporter = crashReporter,
       super(const PlacesState()) {
    on<PlacesLoadRequested>(_onLoad);
    on<PlaceCreated>(_onCreated);
    on<PlaceUpdated>(_onUpdated);
    on<PlaceDeleted>(_onDeleted);
    on<PlaceFavoriteToggled>(_onFavoriteToggled);
    on<PlaceOpened>(_onOpened);
  }

  final String uid;
  final PlacesRepository _repository;

  /// Lets tests flip a fake repository between calls.
  @visibleForTesting
  PlacesRepository get repositoryForTest => _repository;
  final AnalyticsService _analytics;
  final CrashReporter _crashReporter;

  Future<void> _onLoad(
    PlacesLoadRequested event,
    Emitter<PlacesState> emit,
  ) async {
    emit(state.copyWith(status: PlacesStatus.loading, clearError: true));
    try {
      final List<Place> places = await _repository.loadPlaces(uid);
      emit(state.copyWith(status: PlacesStatus.loaded, places: places));
    } catch (error, stack) {
      await _crashReporter.recordError(error, stack, reason: 'Load places');
      emit(
        state.copyWith(
          status: PlacesStatus.failure,
          errorMessage: AppStrings.placesLoadError,
        ),
      );
    }
  }

  Future<void> _onCreated(PlaceCreated event, Emitter<PlacesState> emit) =>
      _change(emit, event.place, [...state.places, event.place]);

  Future<void> _onUpdated(PlaceUpdated event, Emitter<PlacesState> emit) =>
      _change(emit, event.place, [
        for (final Place p in state.places)
          p.id == event.place.id ? event.place : p,
      ]);

  Future<void> _onFavoriteToggled(
    PlaceFavoriteToggled event,
    Emitter<PlacesState> emit,
  ) async {
    final Place? place = state.byId(event.placeId);
    if (place == null) return;
    final Place toggled = place.copyWith(isFavorite: !place.isFavorite);
    await _change(emit, toggled, [
      for (final Place p in state.places) p.id == toggled.id ? toggled : p,
    ]);
    _analytics.logPlaceFavoriteToggled(
      placeId: toggled.id,
      isFavorite: toggled.isFavorite,
    );
  }

  Future<void> _onDeleted(PlaceDeleted event, Emitter<PlacesState> emit) async {
    emit(state.copyWith(clearError: true));
    try {
      await _repository.deletePlace(uid, event.placeId);
      emit(
        state.copyWith(
          places: [
            for (final Place p in state.places)
              if (p.id != event.placeId) p,
          ],
        ),
      );
    } catch (error, stack) {
      await _failSave(emit, error, stack);
    }
  }

  void _onOpened(PlaceOpened event, Emitter<PlacesState> emit) {
    final Place? place = state.byId(event.placeId);
    if (place == null) return;
    _analytics.logPlaceOpened(placeId: place.id, category: place.category.name);
  }

  /// Saves [place] first and only then publishes [next]: the screen never
  /// shows a change that is not on disk.
  Future<void> _change(
    Emitter<PlacesState> emit,
    Place place,
    List<Place> next,
  ) async {
    emit(state.copyWith(clearError: true));
    try {
      await _repository.savePlace(uid, place);
      emit(state.copyWith(places: next));
    } catch (error, stack) {
      await _failSave(emit, error, stack);
    }
  }

  Future<void> _failSave(
    Emitter<PlacesState> emit,
    Object error,
    StackTrace stack,
  ) async {
    await _crashReporter.recordError(error, stack, reason: 'Save place');
    emit(state.copyWith(errorMessage: AppStrings.placesSaveError));
  }
}
```

### 3.2 `CatalogViewCubit` (пошук, фільтр, сортування; Cubit)

Файл: `lib/features/home/bloc/catalog_view_cubit.dart`

```dart
// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/place.dart';
import '../../../data/repositories/settings_repository.dart';
import '../home_filter.dart';
import '../home_sort.dart';

/// How the Home list is shown: search text, category filter, sort order.
final class CatalogViewState extends Equatable {
  const CatalogViewState({
    this.query = '',
    this.filter = HomeFilter.all,
    this.sort = HomeSort.recent,
  });

  /// Ephemeral: typed in the search field, deliberately never persisted.
  final String query;
  final HomeFilter filter;
  final HomeSort sort;

  CatalogViewState copyWith({
    String? query,
    HomeFilter? filter,
    HomeSort? sort,
  }) {
    return CatalogViewState(
      query: query ?? this.query,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [query, filter, sort];
}

/// A *Cubit*, not a Bloc: three trivial setters with no event history to
/// model, so plain methods are enough (no event classes, less boilerplate).
///
/// [filter] and [sort] are remembered per user through the
/// [SettingsRepository] and restored on creation; [query] is not.
class CatalogViewCubit extends Cubit<CatalogViewState> {
  CatalogViewCubit({required this.uid, required SettingsRepository settings})
    : _settings = settings,
      super(const CatalogViewState()) {
    _restore();
  }

  final String uid;
  final SettingsRepository _settings;

  Future<void> _restore() async {
    final CatalogViewPrefs prefs = await _settings.loadCatalogView(uid);
    // Unknown names (e.g. written by a newer app version) are ignored.
    final HomeFilter? filter = HomeFilter.values.asNameMap()[prefs.filter];
    final HomeSort? sort = HomeSort.values.asNameMap()[prefs.sort];
    if (isClosed) return;
    emit(state.copyWith(filter: filter, sort: sort));
  }

  void setQuery(String query) => emit(state.copyWith(query: query));

  void setFilter(HomeFilter filter) {
    emit(state.copyWith(filter: filter));
    _settings.saveCatalogView(uid, filter: filter.name);
  }

  void setSort(HomeSort sort) {
    emit(state.copyWith(sort: sort));
    _settings.saveCatalogView(uid, sort: sort.name);
  }
}

/// The places Home shows: a pure function of the catalog and the view, so it
/// is trivial to test and `build` has no side effects. Returns a new list.
List<Place> visiblePlaces(List<Place> places, CatalogViewState view) {
  final String q = view.query.trim().toLowerCase();
  return places
      .where(view.filter.matches)
      .where(
        (Place p) =>
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.subtitle.toLowerCase().contains(q),
      )
      .toList()
    ..sort(view.sort.compare);
}
```

### 3.3 `LoginBloc` (3.1 реєстрація та логін)

### Події

Файл: `lib/features/auth/bloc/login_event.dart`

```dart
part of 'login_bloc.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => const [];
}

final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class LoginGoogleRequested extends LoginEvent {
  const LoginGoogleRequested();
}

final class LoginAppleRequested extends LoginEvent {
  const LoginAppleRequested();
}

/// The user typed the password of the existing account in the link dialog.
final class LoginGoogleLinkConfirmed extends LoginEvent {
  const LoginGoogleLinkConfirmed({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class LoginGoogleLinkCancelled extends LoginEvent {
  const LoginGoogleLinkCancelled();
}
```

### Стани

Файл: `lib/features/auth/bloc/login_state.dart`

```dart
part of 'login_bloc.dart';

sealed class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => const [];
}

final class LoginInitial extends LoginState {
  const LoginInitial();
}

/// A request is running: buttons show a spinner, fields are read-only.
final class LoginLoading extends LoginState {
  const LoginLoading();
}

final class LoginSuccess extends LoginState {
  const LoginSuccess();
}

final class LoginFailure extends LoginState {
  const LoginFailure(this.message);

  /// Human-readable text from [AuthFailure.message], shown in the banner.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Google sign-in hit an e-mail that already has a password account.
final class LoginLinkRequired extends LoginState {
  const LoginLinkRequired(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}
```

### Блок

Файл: `lib/features/auth/bloc/login_bloc.dart`

```dart
// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/auth_failure.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/analytics_service.dart';

part 'login_event.dart';
part 'login_state.dart';

/// Sign-in with e-mail/password, Google and Apple.
///
/// While a request runs ([LoginLoading]) every new event is ignored, so a
/// second tap can never send a second request. A *successful* sign-in does
/// not navigate: `AuthBloc` sees the new session and `AuthGate` switches the
/// screen. [LoginSuccess] exists so the UI and tests can tell it happened.
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required AuthRepository auth, required AnalyticsService analytics})
    : _auth = auth,
      _analytics = analytics,
      super(const LoginInitial()) {
    on<LoginSubmitted>(_onSubmitted);
    on<LoginGoogleRequested>(_onGoogle);
    on<LoginAppleRequested>(_onApple);
    on<LoginGoogleLinkConfirmed>(_onLinkConfirmed);
    on<LoginGoogleLinkCancelled>((_, Emitter<LoginState> emit) {
      emit(const LoginInitial());
    });
  }

  final AuthRepository _auth;
  final AnalyticsService _analytics;

  bool get _busy => state is LoginLoading;

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (_busy) return;
    emit(const LoginLoading());
    try {
      await _auth.signIn(email: event.email, password: event.password);
      await _analytics.logLogin('password');
      emit(const LoginSuccess());
    } on AuthFailure catch (failure) {
      emit(LoginFailure(failure.message));
    }
  }

  Future<void> _onGoogle(
    LoginGoogleRequested event,
    Emitter<LoginState> emit,
  ) async {
    if (_busy) return;
    emit(const LoginLoading());
    try {
      final bool signedIn = await _auth.signInWithGoogle();
      if (!signedIn) return emit(const LoginInitial()); // sheet dismissed
      await _analytics.logLogin('google');
      emit(const LoginSuccess());
    } on AuthFailure catch (failure) {
      final String? email = failure.email;
      if (failure.type ==
              AuthFailureType.accountExistsWithDifferentCredential &&
          email != null) {
        // The e-mail already has a password account: ask for the password
        // (the UI listens for this state) and link Google to it.
        emit(LoginLinkRequired(email));
      } else {
        emit(LoginFailure(failure.message));
      }
    }
  }

  Future<void> _onApple(
    LoginAppleRequested event,
    Emitter<LoginState> emit,
  ) async {
    if (_busy) return;
    emit(const LoginLoading());
    try {
      final bool signedIn = await _auth.signInWithApple();
      if (!signedIn) return emit(const LoginInitial());
      await _analytics.logLogin('apple');
      emit(const LoginSuccess());
    } on AuthFailure catch (failure) {
      emit(LoginFailure(failure.message));
    }
  }

  Future<void> _onLinkConfirmed(
    LoginGoogleLinkConfirmed event,
    Emitter<LoginState> emit,
  ) async {
    if (_busy) return;
    emit(const LoginLoading());
    try {
      await _auth.completeGoogleLink(
        email: event.email,
        password: event.password,
      );
      await _analytics.logAccountLinked('google.com');
      emit(const LoginSuccess());
    } on AuthFailure catch (failure) {
      emit(LoginFailure(failure.message));
    }
  }
}
```

### 3.4 `RegisterBloc`

Файл: `lib/features/auth/bloc/register_bloc.dart`

```dart
// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/auth_failure.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/analytics_service.dart';

part 'register_event.dart';
part 'register_state.dart';

/// Creates an account with e-mail and password. Same contract as
/// `LoginBloc`: events are ignored while loading, and the new session —
/// not this bloc — switches the screen.
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({
    required AuthRepository auth,
    required AnalyticsService analytics,
  }) : _auth = auth,
       _analytics = analytics,
       super(const RegisterInitial()) {
    on<RegisterSubmitted>(_onSubmitted);
  }

  final AuthRepository _auth;
  final AnalyticsService _analytics;

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    if (state is RegisterLoading) return;
    emit(const RegisterLoading());
    try {
      await _auth.signUp(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
      );
      await _analytics.logSignUp('password');
      emit(const RegisterSuccess());
    } on AuthFailure catch (failure) {
      emit(RegisterFailure(failure.message));
    }
  }
}
```

### 3.5 `ProfileBloc` (3.2 завантаження й редагування профілю)

### Події

Файл: `lib/features/profile/bloc/profile_event.dart`

```dart
part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => const [];
}

/// Subscribe to `userChanges()` (sent once when the bloc is created).
final class ProfileStarted extends ProfileEvent {
  const ProfileStarted();
}

/// Save the edited name and/or photo. `null` fields stay as they are.
final class ProfileUpdated extends ProfileEvent {
  const ProfileUpdated({
    this.displayName,
    this.photoUrl,
    this.photoSource = 'unchanged',
  });

  final String? displayName;
  final String? photoUrl;

  /// For Analytics only: `preset`, `custom` or `unchanged`.
  final String photoSource;

  @override
  List<Object?> get props => [displayName, photoUrl, photoSource];
}

final class ProfileGoogleLinkRequested extends ProfileEvent {
  const ProfileGoogleLinkRequested();
}

/// A screen has shown the error (or is being opened): forget it.
final class ProfileErrorDismissed extends ProfileEvent {
  const ProfileErrorDismissed();
}
```

### Стан

Файл: `lib/features/profile/bloc/profile_state.dart`

```dart
part of 'profile_bloc.dart';

/// `saveFailure` and `linkFailure` are separate so that a failed Google
/// link never shows up as an error on Edit Profile (and vice versa).
enum ProfileStatus { loading, idle, saving, linking, saveFailure, linkFailure }

final class ProfileState extends Equatable {
  const ProfileState({
    this.user,
    this.status = ProfileStatus.loading,
    this.message,
  });

  final AppUser? user;
  final ProfileStatus status;
  final String? message;

  ProfileState copyWith({
    AppUser? user,
    ProfileStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      status: status ?? this.status,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [user, status, message];
}
```

### Блок

Файл: `lib/features/profile/bloc/profile_bloc.dart`

```dart
// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/auth_failure.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/analytics_service.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// The signed-in user's profile: shows it (from `userChanges()`), edits
/// name/photo and links Google. One instance per user (see `UserScope`).
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required AuthRepository auth,
    required AnalyticsService analytics,
  }) : _auth = auth,
       _analytics = analytics,
       // The current user is known synchronously, so the first frame is
       // already filled in; the stream then keeps it up to date.
       super(
         ProfileState(
           user: auth.currentUser,
           status: auth.currentUser == null
               ? ProfileStatus.loading
               : ProfileStatus.idle,
         ),
       ) {
    on<ProfileStarted>(_onStarted);
    on<ProfileUpdated>(_onUpdated);
    on<ProfileGoogleLinkRequested>(_onLinkGoogle);
    on<ProfileErrorDismissed>((_, Emitter<ProfileState> emit) {
      emit(state.copyWith(status: ProfileStatus.idle, clearMessage: true));
    });
  }

  final AuthRepository _auth;
  final AnalyticsService _analytics;

  Future<void> _onStarted(ProfileStarted event, Emitter<ProfileState> emit) {
    return emit.forEach<AppUser?>(
      _auth.userChanges(),
      onData: (AppUser? user) => state.copyWith(
        user: user,
        status: state.status == ProfileStatus.loading
            ? ProfileStatus.idle
            : state.status,
      ),
    );
  }

  Future<void> _onUpdated(
    ProfileUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.status == ProfileStatus.saving) return;
    emit(state.copyWith(status: ProfileStatus.saving, clearMessage: true));
    try {
      await _auth.updateProfile(
        displayName: event.displayName,
        photoUrl: event.photoUrl,
      );
      await _analytics.logProfileUpdated(photoSource: event.photoSource);
      // saving → idle is the "saved" signal the Edit Profile screen waits for.
      emit(state.copyWith(status: ProfileStatus.idle));
    } on AuthFailure catch (failure) {
      emit(
        state.copyWith(
          status: ProfileStatus.saveFailure,
          message: failure.message,
        ),
      );
    }
  }

  Future<void> _onLinkGoogle(
    ProfileGoogleLinkRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.status == ProfileStatus.linking) return;
    emit(state.copyWith(status: ProfileStatus.linking, clearMessage: true));
    try {
      final bool linked = await _auth.linkGoogle();
      if (linked) await _analytics.logAccountLinked('google.com');
      emit(state.copyWith(status: ProfileStatus.idle));
    } on AuthFailure catch (failure) {
      emit(
        state.copyWith(
          status: ProfileStatus.linkFailure,
          message: failure.message,
        ),
      );
    }
  }
}
```

### 3.6 `ChangePasswordCubit` і `ForgotPasswordCubit`

Файл: `lib/features/profile/bloc/change_password_cubit.dart`

```dart
// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/auth_failure.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/analytics_service.dart';

enum ChangePasswordStatus { idle, submitting, success, failure }

final class ChangePasswordState extends Equatable {
  const ChangePasswordState({
    this.status = ChangePasswordStatus.idle,
    this.failureType,
    this.message,
  });

  final ChangePasswordStatus status;

  /// Tells the UI *where* to show the error: under the current-password
  /// field, in a "log in again" dialog, or in the generic banner.
  final AuthFailureType? failureType;
  final String? message;

  @override
  List<Object?> get props => [status, failureType, message];
}

/// A Cubit on purpose (see `CatalogViewCubit`): one method, four states.
/// Re-authentication with the current password happens inside the
/// repository; `requires-recent-login` is reported as a failure type.
class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  ChangePasswordCubit({
    required AuthRepository auth,
    required AnalyticsService analytics,
  }) : _auth = auth,
       _analytics = analytics,
       super(const ChangePasswordState());

  final AuthRepository _auth;
  final AnalyticsService _analytics;

  Future<void> submit({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.status == ChangePasswordStatus.submitting) return;
    emit(const ChangePasswordState(status: ChangePasswordStatus.submitting));
    try {
      await _auth.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      await _analytics.logPasswordChanged();
      emit(const ChangePasswordState(status: ChangePasswordStatus.success));
    } on AuthFailure catch (failure) {
      emit(
        ChangePasswordState(
          status: ChangePasswordStatus.failure,
          failureType: failure.type,
          message: failure.message,
        ),
      );
    }
  }

  /// Forgets a shown error (e.g. the user starts retyping the field).
  void clearError() {
    if (state.status == ChangePasswordStatus.failure) {
      emit(const ChangePasswordState());
    }
  }
}
```

Файл: `lib/features/auth/bloc/forgot_password_cubit.dart`

```dart
// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/auth_failure.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/analytics_service.dart';

enum ForgotPasswordStatus { idle, submitting, sent, failure }

final class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.idle,
    this.message,
  });

  final ForgotPasswordStatus status;
  final String? message;

  @override
  List<Object?> get props => [status, message];
}

/// A Cubit: one action ("send the link") and a plain state, so event
/// classes would only add boilerplate.
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit({
    required AuthRepository auth,
    required AnalyticsService analytics,
  }) : _auth = auth,
       _analytics = analytics,
       super(const ForgotPasswordState());

  final AuthRepository _auth;
  final AnalyticsService _analytics;

  Future<void> sendLink(String email) async {
    if (state.status == ForgotPasswordStatus.submitting) return;
    emit(const ForgotPasswordState(status: ForgotPasswordStatus.submitting));
    try {
      await _auth.sendPasswordResetEmail(email: email);
      await _analytics.logPasswordResetRequested();
      emit(const ForgotPasswordState(status: ForgotPasswordStatus.sent));
    } on AuthFailure catch (failure) {
      emit(
        ForgotPasswordState(
          status: ForgotPasswordStatus.failure,
          message: failure.message,
        ),
      );
    }
  }

  /// "Resend": back to the form.
  void reset() => emit(const ForgotPasswordState());
}
```

### 3.7 `AuthBloc` (сесія)

### Події

Файл: `lib/features/session/bloc/auth_event.dart`

```dart
part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

/// Start listening to the session (sent once, when the bloc is created).
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// The user confirmed "Log Out".
final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
```

### Стани

Файл: `lib/features/session/bloc/auth_state.dart`

```dart
part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

/// Waiting for Firebase to restore the session: the splash is shown.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class Authenticated extends AuthState {
  const Authenticated(this.user, {this.logoutError});

  final AppUser user;

  /// Set when "Log Out" failed; the Profile screen shows it once.
  final String? logoutError;

  @override
  List<Object?> get props => [user.uid, logoutError];
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}
```

### Блок

Файл: `lib/features/session/bloc/auth_bloc.dart`

```dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/auth_failure.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// The session of the whole app: who is signed in, if anybody.
///
/// It turns the repository's `authStateChanges()` stream into states, so
/// `AuthGate` is just `BlocBuilder<AuthBloc, AuthState>` — UI = f(state).
/// Firebase keeps the session on the device, which is why a restart goes
/// `AuthInitial` → `Authenticated` without showing Login (session restore).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._auth)
    // `currentUser` is known synchronously when the SDK has already
    // restored the session; otherwise the splash waits for the stream.
    : super(_initial(_auth.currentUser)) {
    on<AuthStarted>(_onStarted);
    on<AuthLogoutRequested>(_onLogout);
  }

  final AuthRepository _auth;

  static AuthState _initial(AppUser? user) =>
      user == null ? const AuthInitial() : Authenticated(user);

  /// `emit.forEach` keeps listening until the bloc closes and cancels the
  /// subscription itself — no manual `StreamSubscription` to leak.
  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) {
    return emit.forEach<AppUser?>(
      _auth.authStateChanges(),
      onData: (AppUser? user) =>
          user == null ? const Unauthenticated() : Authenticated(user),
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Clear an old error first, so a repeated failure is a new state.
    if (state case Authenticated(:final user, logoutError: != null)) {
      emit(Authenticated(user));
    }
    final AuthState current = state;
    try {
      // The auth stream then emits `Unauthenticated`; this only asks.
      await _auth.signOut();
    } on AuthFailure catch (failure) {
      if (current is Authenticated) {
        emit(Authenticated(current.user, logoutError: failure.message));
      }
    }
  }
}
```

## 3.8 Використання блоків у віджетах

### `MultiRepositoryProvider` і `BlocProvider` (корінь застосунку)

Файл: `lib/main.dart`

Залежності надаються один раз, екрани беруть їх через `context.read<T>()`.

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/dev_launch_options.dart';
import 'data/repositories/auth_repository.dart';
import 'features/session/bloc/auth_bloc.dart';
import 'data/repositories/fake_auth_repository.dart';
import 'data/repositories/firebase_auth_repository.dart';
import 'data/repositories/in_memory_places_repository.dart';
import 'data/repositories/in_memory_settings_repository.dart';
import 'data/repositories/local_places_repository.dart';
import 'data/repositories/places_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/shared_prefs_settings_repository.dart';
import 'data/services/analytics_service.dart';
import 'data/services/crash_reporter.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase must be ready before Auth / Analytics / Crashlytics are used.
  //    The options are generated by `flutterfire configure`.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Crashlytics catches everything that is not handled in code:
  //    errors inside the Flutter framework (build/layout/paint) …
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  //    … and asynchronous errors outside of it (futures, platform channels).
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Portrait only, dark status-bar icons on the light background.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  final CrashReporter crashReporter = FirebaseCrashReporter(
    FirebaseCrashlytics.instance,
  );
  final AuthRepository auth = DevLaunchOptions.useFakeAuth
      ? _fakeAuth()
      : FirebaseAuthRepository(crashReporter: crashReporter);

  // Screenshot mode must not touch the disk: memory repositories, with a
  // short delay so the loading state is visible.
  final bool fake = DevLaunchOptions.useFakeAuth;
  final PlacesRepository places = fake
      ? InMemoryPlacesRepository(
          delay: const Duration(milliseconds: DevLaunchOptions.fakeLoadDelayMs),
          failLoad: DevLaunchOptions.fakeLoadFail,
        )
      : LocalPlacesRepository(
          directory: getApplicationDocumentsDirectory,
          crashReporter: crashReporter,
        );
  final SettingsRepository settings = fake
      ? InMemorySettingsRepository()
      : SharedPrefsSettingsRepository(await SharedPreferences.getInstance());

  // Dependency injection: every service is provided once at the root and
  // read with `context.read<T>()`; tests swap them for fakes.
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: auth),
        RepositoryProvider<PlacesRepository>.value(value: places),
        RepositoryProvider<SettingsRepository>.value(value: settings),
        RepositoryProvider<AnalyticsService>.value(
          value: FirebaseAnalyticsService(FirebaseAnalytics.instance),
        ),
        RepositoryProvider<CrashReporter>.value(value: crashReporter),
      ],
      // The session bloc lives for the whole app run.
      child: BlocProvider<AuthBloc>(
        create: (BuildContext context) =>
            AuthBloc(context.read<AuthRepository>())..add(const AuthStarted()),
        child: const PlacesCatalogApp(),
      ),
    ),
  );
}

/// Screenshot mode (debug only): screens without network or a real account.
AuthRepository _fakeAuth() {
  assert(kDebugMode, 'FAKE_AUTH is meant for debug screenshots only.');
  return DevLaunchOptions.fakeAuth == 'signed_in'
      ? FakeAuthRepository.signedIn()
      : FakeAuthRepository();
}
```

### `MultiBlocProvider` для блоків користувача

Файл: `lib/app/user_scope.dart`

Стоїть у `MaterialApp.builder`, тобто над `Navigator`; `ValueKey(uid)` скидає стан при зміні акаунта.

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/places_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/services/analytics_service.dart';
import '../data/services/crash_reporter.dart';
import '../features/home/bloc/catalog_view_cubit.dart';
import '../features/places/bloc/places_bloc.dart';
import '../features/profile/bloc/profile_bloc.dart';
import '../features/session/bloc/auth_bloc.dart';

/// Creates the *per-user* blocs (`PlacesBloc`, `CatalogViewCubit`,
/// `ProfileBloc`) while somebody is signed in.
///
/// It sits in `MaterialApp.builder`, i.e. **above the Navigator**. That is
/// the key point: pushed routes (Details, forms) are not descendants of
/// the `AuthGate` route, so blocs provided there would be invisible to them.
///
/// `ValueKey(uid)` makes Flutter discard both blocs when the account
/// changes, so a new user starts with a fresh state and their own files.
class UserScope extends StatelessWidget {
  const UserScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (AuthState a, AuthState b) => _uid(a) != _uid(b),
      builder: (BuildContext context, AuthState state) {
        final String? uid = _uid(state);
        if (uid == null) return child;
        return MultiBlocProvider(
          key: ValueKey<String>(uid),
          providers: [
            BlocProvider<PlacesBloc>(
              create: (BuildContext context) => PlacesBloc(
                uid: uid,
                repository: context.read<PlacesRepository>(),
                analytics: context.read<AnalyticsService>(),
                crashReporter: context.read<CrashReporter>(),
              )..add(const PlacesLoadRequested()),
            ),
            BlocProvider<CatalogViewCubit>(
              create: (BuildContext context) => CatalogViewCubit(
                uid: uid,
                settings: context.read<SettingsRepository>(),
              ),
            ),
            BlocProvider<ProfileBloc>(
              create: (BuildContext context) => ProfileBloc(
                auth: context.read<AuthRepository>(),
                analytics: context.read<AnalyticsService>(),
              )..add(const ProfileStarted()),
            ),
          ],
          child: child,
        );
      },
    );
  }

  static String? _uid(AuthState state) =>
      state is Authenticated ? state.user.uid : null;
}
```

### `BlocBuilder` + `BlocListener` (`AuthGate`)

Файл: `lib/app/auth_gate.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/app_logo.dart';
import '../data/services/analytics_service.dart';
import '../data/services/crash_reporter.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/session/bloc/auth_bloc.dart';
import '../features/shell/main_shell.dart';

/// Root of the app: shows Login or [MainShell] depending on [AuthBloc].
///
/// * UI = f(state): a `BlocBuilder` maps `AuthState` to a screen. Firebase
///   keeps the session on the device, so after a restart a signed-in user
///   goes straight to [MainShell] — session restore.
/// * Side effects (clearing pushed auth screens, analytics / crash user id)
///   live in a `BlocListener`, never inside `build()`.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Who is signed in is tagged on Analytics and Crashlytics reports.
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (AuthState before, AuthState now) =>
              _uid(before) != _uid(now),
          listener: (BuildContext context, AuthState state) {
            final String? uid = _uid(state);
            context.read<AnalyticsService>().setUserId(uid);
            context.read<CrashReporter>().setUserIdentifier(uid);
          },
        ),
        // Signed in / out from a pushed screen (Register, Forgot, …): drop
        // those routes so the gate's new root is visible. Not for the very
        // first state (session restore) — nothing is pushed yet.
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (AuthState before, AuthState now) =>
              before is! AuthInitial && _uid(before) != _uid(now),
          listener: (BuildContext context, AuthState state) {
            Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (BuildContext context, AuthState state) => switch (state) {
          AuthInitial() => const _Splash(),
          Unauthenticated() => const LoginScreen(),
          // A new key per user resets tab state after switching accounts.
          Authenticated(:final user) => MainShell(
            key: ValueKey<String>(user.uid),
          ),
        },
      ),
    );
  }

  static String? _uid(AuthState state) =>
      state is Authenticated ? state.user.uid : null;
}

/// Shown for the split second while Firebase restores the session.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.background,
      child: Center(child: AppLogo.large()),
    );
  }
}
```

### `BlocListener` (діалог помилки збереження)

Файл: `lib/features/shell/main_shell.dart` (фрагмент)

Діалог — побічний ефект, тому `BlocListener`, а не `BlocBuilder`.

```dart
    // A failed save (the list itself is intact) is reported once, here.
    return BlocListener<PlacesBloc, PlacesState>(
      listenWhen: (PlacesState before, PlacesState now) =>
          now.status == PlacesStatus.loaded &&
          now.errorMessage != null &&
          before.errorMessage != now.errorMessage,
      listener: (BuildContext context, PlacesState state) {
        AppConfirmDialog.show(
          context,
          title: AppStrings.placesSaveErrorTitle,
          message: state.errorMessage!,
          confirmLabel: AppStrings.ok,
          cancelLabel: null,
        );
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: const [HomeScreen(), FavoritesScreen(), ProfileScreen()],
        ),
        bottomNavigationBar: AppBottomNavBar(
          items: _tabs,
          currentIndex: _currentIndex,
          onTap: _selectTab,
        ),
      ),
    );
  }
}
```

### `context.select` (Favorites — відфільтроване представлення того самого каталогу)

Файл: `lib/features/favorites/screens/favorites_screen.dart` (фрагмент)

Екран перебудовується лише коли змінюється список обраних.

```dart
    // Favorites is a *view* of the same catalog Home shows: one source of
    // truth, so a heart tapped anywhere is reflected here at once.
    final List<Place> favorites = context.select(
      (PlacesBloc b) =>
          b.state.places.where((Place p) => p.isFavorite).toList(),
    );
```

### `BlocProvider` + `context.read` (екран входу)

Файл: `lib/features/auth/screens/login_screen.dart` (фрагмент)

Блок живе стільки, скільки живе екран.

```dart
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The bloc lives exactly as long as this screen.
    return BlocProvider<LoginBloc>(
      create: (BuildContext context) => LoginBloc(
        auth: context.read<AuthRepository>(),
        analytics: context.read<AnalyticsService>(),
      ),
      child: const LoginLinkListener(child: _LoginView()),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  // Created once per State — never in build(), or every rebuild would
  // create a new form and lose the field state.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
```

### Відправлення події у блок

Файл: `lib/features/auth/screens/login_screen.dart` (фрагмент)

Валідація форми, потім `add(LoginSubmitted)`; повторне натискання під час `LoginLoading` блок ігнорує.

```dart
  void _submit() {
    FocusScope.of(context).unfocus();
    // After the first attempt, fields re-validate while the user types.
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // A tap during loading is ignored by the bloc itself.
    context.read<LoginBloc>().add(
      LoginSubmitted(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }
```

### `BlocListener` для об'єднання акаунтів

Файл: `lib/features/auth/widgets/social_sign_in.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/social_auth_button.dart';
import '../bloc/login_bloc.dart';

/// Sends the tapped provider to `LoginBloc` (used by Login *and* Register,
/// which both show the same Google/Apple buttons).
void startSocialSignIn(BuildContext context, SocialProvider provider) {
  final LoginBloc bloc = context.read<LoginBloc>();
  switch (provider) {
    case SocialProvider.apple:
      bloc.add(const LoginAppleRequested());
    case SocialProvider.google:
      bloc.add(const LoginGoogleRequested());
  }
}

/// Reacts to `LoginLinkRequired`: Google's e-mail already has a password
/// account, so ask for that password and let the bloc link Google to it —
/// one account, two sign-in methods. A dialog is a side effect, which is
/// exactly what `BlocListener` is for (not `BlocBuilder`).
class LoginLinkListener extends StatelessWidget {
  const LoginLinkListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (_, LoginState now) => now is LoginLinkRequired,
      listener: (BuildContext context, LoginState state) async {
        final String email = (state as LoginLinkRequired).email;
        final LoginBloc bloc = context.read<LoginBloc>();
        final String? password = await showCupertinoDialog<String>(
          context: context,
          builder: (_) => _LinkPasswordDialog(email: email),
        );
        if (password == null || password.isEmpty) {
          bloc.add(const LoginGoogleLinkCancelled());
        } else {
          bloc.add(LoginGoogleLinkConfirmed(email: email, password: password));
        }
      },
      child: child,
    );
  }
}

class _LinkPasswordDialog extends StatefulWidget {
  const _LinkPasswordDialog({required this.email});

  final String email;

  @override
  State<_LinkPasswordDialog> createState() => _LinkPasswordDialogState();
}

class _LinkPasswordDialogState extends State<_LinkPasswordDialog> {
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_password.text);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(AppStrings.linkGoogleTitle),
      content: Column(
        children: [
          Text('${AppStrings.linkGoogleMessage}\n${widget.email}'),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: _password,
            autofocus: true,
            obscureText: true,
            placeholder: AppStrings.passwordLabel,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _submit,
          child: const Text(AppStrings.connect),
        ),
      ],
    );
  }
}
```

### `BlocListener` + `context.watch` (ChangePasswordCubit)

Файл: `lib/features/profile/screens/change_password_screen.dart` (фрагмент)

Куди виводиться помилка, визначає `failureType`.

```dart
  Future<void> _onResult(
    BuildContext context,
    ChangePasswordState state,
  ) async {
    final ChangePasswordCubit cubit = context.read<ChangePasswordCubit>();
    final NavigatorState navigator = Navigator.of(context);
    final AuthBloc session = context.read<AuthBloc>();
    if (state.status == ChangePasswordStatus.success) {
      await AppConfirmDialog.show(
        context,
        title: AppStrings.passwordUpdatedTitle,
        message: AppStrings.passwordUpdatedMessage,
        confirmLabel: AppStrings.ok,
        cancelLabel: null,
      );
      navigator.pop();
    } else if (state.failureType == AuthFailureType.requiresRecentLogin) {
      // The session is too old for a sensitive change: explain, offer to
      // log out and back in.
      final bool signOut = await AppConfirmDialog.show(
        context,
        title: AppStrings.signInAgainTitle,
        message: AppStrings.errorRecentLogin,
        confirmLabel: AppStrings.logOut,
      );
      cubit.clearError();
      if (signOut) session.add(const AuthLogoutRequested());
    }
  }
```

## 4. Локальне сховище

### Інтерфейс налаштувань

Файл: `lib/data/repositories/settings_repository.dart`

```dart
/// The Home list settings that survive a restart.
///
/// Stored as enum *names* (strings) so the data layer does not depend on
/// the Home feature's `HomeFilter` / `HomeSort`; the cubit parses them.
class CatalogViewPrefs {
  const CatalogViewPrefs({this.filter, this.sort});

  final String? filter;
  final String? sort;
}

/// Small per-user preferences (key–value data, the SharedPreferences use
/// case). The search text is deliberately *not* stored: it is ephemeral.
abstract interface class SettingsRepository {
  Future<CatalogViewPrefs> loadCatalogView(String uid);

  Future<void> saveCatalogView(String uid, {String? filter, String? sort});
}
```

### `SharedPreferences`: фільтр і сортування по користувачу

Файл: `lib/data/repositories/shared_prefs_settings_repository.dart`

```dart
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_repository.dart';

/// [SettingsRepository] on top of `shared_preferences`.
///
/// The classic [SharedPreferences] (instance obtained once with
/// `getInstance()` in `main`) is used because it is what the course
/// material describes and it is trivially mockable in tests.
///
/// Keys carry the uid (`<uid>.catalog.filter`) so two accounts on one
/// device keep separate settings. SharedPreferences gives no durability
/// guarantee for a write that is interrupted, which is acceptable for a
/// sort order — it would never be used for the catalog itself.
class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static String _filterKey(String uid) => '$uid.catalog.filter';
  static String _sortKey(String uid) => '$uid.catalog.sort';

  @override
  Future<CatalogViewPrefs> loadCatalogView(String uid) async =>
      CatalogViewPrefs(
        filter: _prefs.getString(_filterKey(uid)),
        sort: _prefs.getString(_sortKey(uid)),
      );

  @override
  Future<void> saveCatalogView(
    String uid, {
    String? filter,
    String? sort,
  }) async {
    if (filter != null) await _prefs.setString(_filterKey(uid), filter);
    if (sort != null) await _prefs.setString(_sortKey(uid), sort);
  }
}
```

### Інтерфейс репозиторію каталогу

Файл: `lib/data/repositories/places_repository.dart`

```dart
import '../models/place.dart';

/// Where the catalog of one user lives.
///
/// An interface (not a concrete class) so the BLoC depends only on *what*
/// is stored, never on *how*: the app uses a JSON file, tests and the
/// screenshot mode use memory. The uid is a parameter, not a constructor
/// argument, because the repository is created before anybody signs in.
abstract interface class PlacesRepository {
  /// Every place of [uid]; seeds the demo catalog on the first run.
  Future<List<Place>> loadPlaces(String uid);

  /// Inserts a new place or replaces the one with the same id.
  Future<void> savePlace(String uid, Place place);

  Future<void> deletePlace(String uid, String placeId);
}
```

### `LocalPlacesRepository`: JSON-файл (`path_provider`), атомарний запис

Файл: `lib/data/repositories/local_places_repository.dart`

```dart
// The constructor takes named parameters for private fields, which cannot
// be initializing formals.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../mock/mock_places.dart';
import '../models/place.dart';
import '../services/crash_reporter.dart';
import 'places_repository.dart';

/// Stores each user's catalog as a JSON file (`places_<uid>.json`).
///
/// Why a file and not SharedPreferences: the catalog is a growing list of
/// nested objects, while SharedPreferences is meant for a few small
/// key–value settings. Why not a database: the volume is tiny and the
/// whole list is shown at once, so one file is the simplest thing that
/// works (and the brief forbids extra dependencies).
///
/// * Per user: the file name contains the uid, so accounts never see each
///   other's places.
/// * Atomic write: data goes to a temporary file that then *replaces* the
///   real one, so a crash mid-write cannot leave half a JSON document.
/// * Damaged file: reported to Crashlytics as non-fatal and replaced by the
///   demo catalog, so the app still opens.
class LocalPlacesRepository implements PlacesRepository {
  /// [directory] is injected (production: the app documents directory) so
  /// tests can point the repository at a temporary folder.
  LocalPlacesRepository({
    required Future<Directory> Function() directory,
    required CrashReporter crashReporter,
    List<Place>? seed,
  }) : _directory = directory,
       _crashReporter = crashReporter,
       _seed = seed ?? mockPlaces;

  final Future<Directory> Function() _directory;
  final CrashReporter _crashReporter;
  final List<Place> _seed;

  final Map<String, List<Place>> _cache = {};

  /// Writes are chained so two quick changes never interleave on disk.
  Future<void> _lastWrite = Future<void>.value();

  Future<File> _file(String uid) async {
    final Directory dir = await _directory();
    final String safe = uid.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return File('${dir.path}/places_$safe.json');
  }

  @override
  Future<List<Place>> loadPlaces(String uid) async {
    final List<Place>? cached = _cache[uid];
    if (cached != null) return List.of(cached);

    final File file = await _file(uid);
    List<Place> places;
    if (!await file.exists()) {
      places = List.of(_seed);
      await _write(uid, places);
    } else {
      try {
        places = _decode(await file.readAsString());
      } catch (error, stack) {
        await _crashReporter.recordError(
          error,
          stack,
          reason: 'Damaged places file, restored demo catalog',
        );
        places = List.of(_seed);
        await _write(uid, places);
      }
    }
    _cache[uid] = places;
    return List.of(places);
  }

  @override
  Future<void> savePlace(String uid, Place place) async {
    final List<Place> list = await _mutable(uid);
    final int index = list.indexWhere((Place p) => p.id == place.id);
    if (index == -1) {
      list.add(place);
    } else {
      list[index] = place;
    }
    await _write(uid, list);
  }

  @override
  Future<void> deletePlace(String uid, String placeId) async {
    final List<Place> list = await _mutable(uid);
    list.removeWhere((Place p) => p.id == placeId);
    await _write(uid, list);
  }

  Future<List<Place>> _mutable(String uid) async {
    await loadPlaces(uid);
    return _cache[uid]!;
  }

  static List<Place> _decode(String source) {
    final Object? root = jsonDecode(source);
    if (root is! Map<String, Object?>) {
      throw const FormatException('Root of the places file is not an object');
    }
    return [
      for (final Object? item in root['places'] as List<Object?>)
        Place.fromJson((item as Map<Object?, Object?>).cast()),
    ];
  }

  Future<void> _write(String uid, List<Place> places) {
    final String json = const JsonEncoder.withIndent(' ').convert({
      'version': 1,
      'places': places.map((Place p) => p.toJson()).toList(),
    });
    return _lastWrite = _lastWrite.then((_) async {
      final File file = await _file(uid);
      final File temp = File('${file.path}.tmp');
      await temp.writeAsString(json, flush: true);
      await temp.rename(file.path);
    });
  }
}
```

### `InMemoryPlacesRepository` (тести й режим скриншотів)

Файл: `lib/data/repositories/in_memory_places_repository.dart`

```dart
import '../mock/mock_places.dart';
import '../models/place.dart';
import 'places_repository.dart';

/// Keeps catalogs in memory: used by tests and the `FAKE_AUTH` screenshot
/// mode, where touching the disk would make runs depend on earlier runs.
class InMemoryPlacesRepository implements PlacesRepository {
  /// [seed] is what a user sees on the first load (the Figma demo data by
  /// default). [delay] simulates a slow disk so loading states are visible;
  /// [failLoad] makes loading throw, to test the error state.
  InMemoryPlacesRepository({
    List<Place>? seed,
    this.delay = Duration.zero,
    this.failLoad = false,
  }) : _seed = seed ?? mockPlaces;

  final List<Place> _seed;
  final Duration delay;
  bool failLoad;
  final Map<String, List<Place>> _byUser = {};

  @override
  Future<List<Place>> loadPlaces(String uid) async {
    await Future<void>.delayed(delay);
    if (failLoad) throw StateError('Simulated load failure');
    return List.of(_byUser.putIfAbsent(uid, () => List.of(_seed)));
  }

  @override
  Future<void> savePlace(String uid, Place place) async {
    final List<Place> list = _byUser.putIfAbsent(uid, () => List.of(_seed));
    final int index = list.indexWhere((Place p) => p.id == place.id);
    if (index == -1) {
      list.add(place);
    } else {
      list[index] = place;
    }
  }

  @override
  Future<void> deletePlace(String uid, String placeId) async {
    _byUser
        .putIfAbsent(uid, () => List.of(_seed))
        .removeWhere((Place p) => p.id == placeId);
  }
}
```

### Модель `Place`: `toJson` / `fromJson`, повний `copyWith`

Файл: `lib/data/models/place.dart`

```dart
import 'place_category.dart';
import 'place_photo.dart';
import 'review.dart';

/// A visited venue — the central entity of the catalog.
///
/// Immutable: every field is `final`, and changes (e.g. toggling favourite)
/// produce a new instance through [copyWith].
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.subtitle,
    required this.address,
    required this.visitDate,
    required this.coverImage,
    this.review,
    this.isFavorite = false,
    this.latitude,
    this.longitude,
    this.photos = const [],
  });

  /// Reads the map written by [toJson]. The category is stored by `name`, so
  /// reordering the enum never corrupts saved data; an unknown name throws
  /// [ArgumentError], which the repository treats as a damaged file.
  factory Place.fromJson(Map<String, Object?> json) {
    final Object? review = json['review'];
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      category: PlaceCategory.values.byName(json['category'] as String),
      subtitle: json['subtitle'] as String,
      address: json['address'] as String,
      visitDate: DateTime.parse(json['visitDate'] as String),
      coverImage: json['coverImage'] as String,
      review: review == null
          ? null
          : Review.fromJson((review as Map<Object?, Object?>).cast()),
      isFavorite: json['isFavorite'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      photos: [
        for (final Object? p in json['photos'] as List<Object?>? ?? const [])
          PlacePhoto.fromJson((p as Map<Object?, Object?>).cast()),
      ],
    );
  }

  final String id;
  final String name;
  final PlaceCategory category;

  /// Cuisine / sub-type shown under the name, e.g. "Museum & Art".
  final String subtitle;
  final String address;
  final DateTime visitDate;
  final String coverImage;
  final Review? review;
  final bool isFavorite;
  final double? latitude;
  final double? longitude;
  final List<PlacePhoto> photos;

  /// Plain JSON map shared by local storage and the Export Archive screen.
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'subtitle': subtitle,
    'address': address,
    'visitDate': visitDate.toIso8601String(),
    'coverImage': coverImage,
    'review': review?.toJson(),
    'isFavorite': isFavorite,
    'latitude': latitude,
    'longitude': longitude,
    'photos': [for (final PlacePhoto p in photos) p.toJson()],
  };

  int get photosCount => photos.length;

  /// Large photo for Place Details: the first attached photo, or the cover.
  String get heroImage => photos.isEmpty ? coverImage : photos.first.imageAsset;

  /// Overall rating, or 0 when the place has not been reviewed yet.
  double get rating => review?.overallRating ?? 0;

  /// Returns a copy with the given fields replaced (immutable update).
  ///
  /// Every field is replaceable because the Edit Place form rebuilds the
  /// whole record; `null` arguments keep the current value.
  Place copyWith({
    String? name,
    PlaceCategory? category,
    String? subtitle,
    String? address,
    DateTime? visitDate,
    String? coverImage,
    Review? review,
    bool? isFavorite,
    double? latitude,
    double? longitude,
    List<PlacePhoto>? photos,
  }) {
    return Place(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      subtitle: subtitle ?? this.subtitle,
      address: address ?? this.address,
      visitDate: visitDate ?? this.visitDate,
      coverImage: coverImage ?? this.coverImage,
      review: review ?? this.review,
      isFavorite: isFavorite ?? this.isFavorite,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photos: photos ?? this.photos,
    );
  }
}
```

### Модель `Review`

Файл: `lib/data/models/review.dart`

```dart
/// Multi-criteria review of a visit.
///
/// Only [overallRating] is required; the detailed ratings are nullable
/// (`double?`) because the user may skip them — Dart null safety forces
/// every reader to handle that case explicitly.
class Review {
  const Review({
    required this.overallRating,
    this.foodRating,
    this.serviceRating,
    this.atmosphereRating,
    this.textNote = '',
    this.tags = const [],
    this.updatedAt,
  }) : assert(overallRating >= 1 && overallRating <= 5);

  /// Reads the map written by [toJson]. Hand-written (no code generation)
  /// so the whole serialisation is visible in the report.
  factory Review.fromJson(Map<String, Object?> json) {
    final String? updated = json['updatedAt'] as String?;
    return Review(
      overallRating: (json['overallRating'] as num).toDouble(),
      foodRating: (json['foodRating'] as num?)?.toDouble(),
      serviceRating: (json['serviceRating'] as num?)?.toDouble(),
      atmosphereRating: (json['atmosphereRating'] as num?)?.toDouble(),
      textNote: json['textNote'] as String? ?? '',
      tags: [
        ...(json['tags'] as List<Object?>? ?? const <Object?>[]).cast<String>(),
      ],
      updatedAt: updated == null ? null : DateTime.parse(updated),
    );
  }

  final double overallRating;
  final double? foodRating;
  final double? serviceRating;
  final double? atmosphereRating;
  final String textNote;
  final List<String> tags;

  /// When the note was last edited; `null` for imported records.
  final DateTime? updatedAt;

  /// Plain JSON map; dates are ISO-8601 strings.
  Map<String, Object?> toJson() => {
    'overallRating': overallRating,
    'foodRating': foodRating,
    'serviceRating': serviceRating,
    'atmosphereRating': atmosphereRating,
    'textNote': textNote,
    'tags': tags,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  /// Returns a copy with the given fields replaced; `null` keeps the value.
  Review copyWith({
    double? overallRating,
    double? foodRating,
    double? serviceRating,
    double? atmosphereRating,
    String? textNote,
    List<String>? tags,
    DateTime? updatedAt,
  }) {
    return Review(
      overallRating: overallRating ?? this.overallRating,
      foodRating: foodRating ?? this.foodRating,
      serviceRating: serviceRating ?? this.serviceRating,
      atmosphereRating: atmosphereRating ?? this.atmosphereRating,
      textNote: textNote ?? this.textNote,
      tags: tags ?? this.tags,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

### Як блок викликає сховище

Файл: `lib/features/places/bloc/places_bloc.dart` (фрагмент)

Спершу запис через репозиторій, лише потім `emit` нового списку.

```dart
  /// Saves [place] first and only then publishes [next]: the screen never
  /// shows a change that is not on disk.
  Future<void> _change(
    Emitter<PlacesState> emit,
    Place place,
    List<Place> next,
  ) async {
    emit(state.copyWith(clearError: true));
    try {
      await _repository.savePlace(uid, place);
      emit(state.copyWith(places: next));
    } catch (error, stack) {
      await _failSave(emit, error, stack);
    }
  }
```

## 5. Повний `main.dart`

Файл: `lib/main.dart`

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/dev_launch_options.dart';
import 'data/repositories/auth_repository.dart';
import 'features/session/bloc/auth_bloc.dart';
import 'data/repositories/fake_auth_repository.dart';
import 'data/repositories/firebase_auth_repository.dart';
import 'data/repositories/in_memory_places_repository.dart';
import 'data/repositories/in_memory_settings_repository.dart';
import 'data/repositories/local_places_repository.dart';
import 'data/repositories/places_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/shared_prefs_settings_repository.dart';
import 'data/services/analytics_service.dart';
import 'data/services/crash_reporter.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase must be ready before Auth / Analytics / Crashlytics are used.
  //    The options are generated by `flutterfire configure`.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Crashlytics catches everything that is not handled in code:
  //    errors inside the Flutter framework (build/layout/paint) …
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  //    … and asynchronous errors outside of it (futures, platform channels).
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Portrait only, dark status-bar icons on the light background.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  final CrashReporter crashReporter = FirebaseCrashReporter(
    FirebaseCrashlytics.instance,
  );
  final AuthRepository auth = DevLaunchOptions.useFakeAuth
      ? _fakeAuth()
      : FirebaseAuthRepository(crashReporter: crashReporter);

  // Screenshot mode must not touch the disk: memory repositories, with a
  // short delay so the loading state is visible.
  final bool fake = DevLaunchOptions.useFakeAuth;
  final PlacesRepository places = fake
      ? InMemoryPlacesRepository(
          delay: const Duration(milliseconds: DevLaunchOptions.fakeLoadDelayMs),
          failLoad: DevLaunchOptions.fakeLoadFail,
        )
      : LocalPlacesRepository(
          directory: getApplicationDocumentsDirectory,
          crashReporter: crashReporter,
        );
  final SettingsRepository settings = fake
      ? InMemorySettingsRepository()
      : SharedPrefsSettingsRepository(await SharedPreferences.getInstance());

  // Dependency injection: every service is provided once at the root and
  // read with `context.read<T>()`; tests swap them for fakes.
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: auth),
        RepositoryProvider<PlacesRepository>.value(value: places),
        RepositoryProvider<SettingsRepository>.value(value: settings),
        RepositoryProvider<AnalyticsService>.value(
          value: FirebaseAnalyticsService(FirebaseAnalytics.instance),
        ),
        RepositoryProvider<CrashReporter>.value(value: crashReporter),
      ],
      // The session bloc lives for the whole app run.
      child: BlocProvider<AuthBloc>(
        create: (BuildContext context) =>
            AuthBloc(context.read<AuthRepository>())..add(const AuthStarted()),
        child: const PlacesCatalogApp(),
      ),
    ),
  );
}

/// Screenshot mode (debug only): screens without network or a real account.
AuthRepository _fakeAuth() {
  assert(kDebugMode, 'FAKE_AUTH is meant for debug screenshots only.');
  return DevLaunchOptions.fakeAuth == 'signed_in'
      ? FakeAuthRepository.signedIn()
      : FakeAuthRepository();
}
```

