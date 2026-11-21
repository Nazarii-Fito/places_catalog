import 'dart:ui';

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/map_defaults.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/coordinates_formatter.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/osm_tile_layer.dart';
import '../../../core/widgets/pressable_opacity.dart';
import '../../../data/models/geocoding_result.dart';
import '../../../data/repositories/geocoding_repository.dart';
import '../bloc/location_picker_cubit.dart';
import '../../../core/widgets/app_text_link.dart';
import '../../../core/widgets/primary_button.dart';

/// Location picker (FR11) shown as a full-screen modal.
///
/// A real OpenStreetMap map (`flutter_map`) with a **fixed pin in the
/// centre**: the chosen point is whatever is under the pin, so the user
/// pans and zooms the map instead of moving a marker. The address of that
/// point is looked up by `LocationPickerCubit` (reverse geocoding, after the
/// map stops moving); typing an address and submitting searches for it.
/// "Confirm" pops a [PickedLocation]; "Cancel" pops `null`.
class LocationPickerScreen extends StatelessWidget {
  const LocationPickerScreen({super.key, this.initial});

  /// The place's current location when editing; `null` for a new place.
  final LocationPickerArgs? initial;

  @override
  Widget build(BuildContext context) {
    final LocationPickerArgs? start = initial;
    return BlocProvider<LocationPickerCubit>(
      create: (BuildContext context) => LocationPickerCubit(
        geocoding: context.read<GeocodingRepository>(),
        initialCenter: start != null && start.hasPoint
            ? LatLng(start.latitude!, start.longitude!)
            : MapDefaults.center,
        initialAddress: start?.address ?? '',
      ),
      child: _LocationPickerView(initial: start),
    );
  }
}

class _LocationPickerView extends StatefulWidget {
  const _LocationPickerView({required this.initial});

  final LocationPickerArgs? initial;

  @override
  State<_LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<_LocationPickerView> {
  final MapController _map = MapController();
  late final TextEditingController _queryController = TextEditingController(
    text: widget.initial?.address ?? '',
  );

  /// The map is being dragged: the pin lifts, like a real one.
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    final LocationPickerArgs? start = widget.initial;
    // An old record has an address but no point: try to find it on the map.
    if (start != null && !start.hasPoint && start.address.isNotEmpty) {
      context.read<LocationPickerCubit>().centerOnAddress(start.address);
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _map.dispose();
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    // Moves made by the cubit itself (after a search) are not the user's.
    if (event.source == MapEventSource.mapController) return;
    final LocationPickerCubit cubit = context.read<LocationPickerCubit>();
    if (event is MapEventMoveStart) {
      setState(() => _dragging = true);
    } else if (event is MapEventMoveEnd) {
      setState(() => _dragging = false);
      cubit.mapMoved(event.camera.center);
    } else if (event is MapEventMove) {
      cubit.mapMoving(event.camera.center);
    }
  }

  void _search() {
    FocusScope.of(context).unfocus();
    context.read<LocationPickerCubit>().search(_queryController.text);
  }

  void _clear() {
    _queryController.clear();
    setState(() {});
  }

  void _confirm() {
    Navigator.of(context).pop(context.read<LocationPickerCubit>().picked);
  }

  @override
  Widget build(BuildContext context) {
    final LocationPickerCubit cubit = context.read<LocationPickerCubit>();
    return Scaffold(
      body: BlocListener<LocationPickerCubit, LocationPickerState>(
        listenWhen: (before, now) => before.recenterTick != now.recenterTick,
        listener: (BuildContext context, LocationPickerState state) {
          _map.move(state.center, MapDefaults.focusZoom);
          _queryController.text = state.address;
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: cubit.state.center,
                initialZoom: MapDefaults.zoom,
                backgroundColor: OsmTileLayer.background,
                onMapEvent: _onMapEvent,
              ),
              children: const [OsmTileLayer()],
            ),
            const IgnorePointer(
              child: DecoratedBox(
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
            ),
            // The pin's tip is the chosen point (the centre of the map).
            IgnorePointer(
              child: Align(
                alignment: const Alignment(0, -0.06),
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 150),
                  offset: Offset(0, _dragging ? -0.12 : 0),
                  child: const _DropPin(),
                ),
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.only(bottom: AppSpacing.l),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    _SearchBar(
                      controller: _queryController,
                      onSubmitted: _search,
                      onClear: _clear,
                    ),
                    const _SearchResults(),
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _AttributionChip(),
                      ),
                    ),
                    _LocationCard(onConfirm: _confirm),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The map credit on a small frosted chip, always visible above the card.
class _AttributionChip extends StatelessWidget {
  const _AttributionChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.glass90,
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      child: const OsmAttribution(),
    );
  }
}

/// Several matches of a search, in the same frosted style as the panel.
class _SearchResults extends StatelessWidget {
  const _SearchResults();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationPickerCubit, LocationPickerState>(
      buildWhen: (a, b) => a.results != b.results,
      builder: (BuildContext context, LocationPickerState state) {
        if (state.results.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s),
          child: _Glass(
            color: AppColors.glass95,
            radius: AppRadii.lg,
            blur: 12,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                for (final GeocodingResult r in state.results)
                  PressableOpacity(
                    onTap: () =>
                        context.read<LocationPickerCubit>().selectResult(r),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l,
                        vertical: AppSpacing.sm,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.title,
                              style: AppTextStyles.subheadline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              r.displayName,
                              style: AppTextStyles.footnote.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final VoidCallback onClear;

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
                      // Search runs on submit only (no autocomplete: the
                      // public Nominatim service forbids it).
                      onSubmitted: (_) => onSubmitted(),
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration.collapsed(
                        hintText: AppStrings.location,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onClear,
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
    return BlocBuilder<LocationPickerCubit, LocationPickerState>(
      builder: (BuildContext context, LocationPickerState state) {
        final bool busy =
            state.status == LocationPickerStatus.resolving ||
            state.status == LocationPickerStatus.searching;
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
                child: busy
                    ? const CupertinoActivityIndicator()
                    : const AppSvgIcon(AppAssets.iconLocationArrow),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xxs,
                children: [
                  Text(
                    state.hasAddress
                        ? state.title
                        : AppStrings.pickedPlaceTitle,
                    style: AppTextStyles.headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    state.hasAddress ? state.address : AppStrings.moveMapHint,
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
                        Flexible(
                          child: Text(
                            formatCoordinates(
                              state.center.latitude,
                              state.center.longitude,
                            ),
                            style: AppTextStyles.footnote.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.status == LocationPickerStatus.error)
                    Text(
                      state.message ?? AppStrings.errorUnknown,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.destructive,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
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
