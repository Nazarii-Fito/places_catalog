// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/geocoding_failure.dart';
import '../../../data/models/geocoding_result.dart';
import '../../../data/repositories/geocoding_repository.dart';
import '../../../data/repositories/venues_repository.dart';
import '../../../data/services/location_service.dart';

enum LocationPickerStatus {
  /// Nothing is running; the card shows the current point.
  idle,

  /// An address / venue search (submitted text) is running.
  searching,

  /// The address of the map centre is being looked up.
  resolving,

  /// The phone's position is being read.
  locating,

  /// The card shows a resolved address for the current point.
  ready,

  /// A search or lookup failed; [LocationPickerState.message] says why.
  error,
}

/// What part of the map the user sees; used to ask for venues in view.
class MapViewport {
  const MapViewport({required this.bounds, required this.zoom});

  final GeoBounds bounds;
  final double zoom;
}

class LocationPickerState extends Equatable {
  const LocationPickerState({
    required this.center,
    this.status = LocationPickerStatus.idle,
    this.title = '',
    this.address = '',
    this.results = const [],
    this.venues = const [],
    this.selected,
    this.message,
    this.recenterTick = 0,
  });

  /// The chosen point: always the centre of the map under the pin.
  final LatLng center;
  final LocationPickerStatus status;

  /// Card header (first part of the address) and the full address.
  final String title;
  final String address;

  /// Several matches of the last search, shown under the search panel.
  final List<GeocodingResult> results;

  /// Venues around the visible part of the map, drawn as markers.
  final List<GeocodingResult> venues;

  /// The venue the user tapped or picked from the results (its name and
  /// kind go back to the form); `null` once the map is moved away.
  final GeocodingResult? selected;

  final String? message;

  /// Increments when the *cubit* wants the map to jump to [center] (after a
  /// search or "my location"); a drag by the user does not change it. The
  /// screen moves the map controller when it changes, which avoids a
  /// feedback loop.
  final int recenterTick;

  bool get hasAddress => address.isNotEmpty;

  LocationPickerState copyWith({
    LatLng? center,
    LocationPickerStatus? status,
    String? title,
    String? address,
    List<GeocodingResult>? results,
    List<GeocodingResult>? venues,
    GeocodingResult? selected,
    bool clearSelected = false,
    String? message,
    bool clearMessage = false,
    bool recenter = false,
  }) {
    return LocationPickerState(
      center: center ?? this.center,
      status: status ?? this.status,
      title: title ?? this.title,
      address: address ?? this.address,
      results: results ?? this.results,
      venues: venues ?? this.venues,
      selected: clearSelected ? null : selected ?? this.selected,
      message: clearMessage ? null : message ?? this.message,
      recenterTick: recenter ? recenterTick + 1 : recenterTick,
    );
  }

  @override
  List<Object?> get props => [
    center,
    status,
    title,
    address,
    results,
    venues,
    selected,
    message,
    recenterTick,
  ];
}

/// State of the location picker: search, "my location", the point under the
/// pin, its address and the venues around it.
///
/// * Search happens **on submit** only (the public Nominatim service forbids
///   autocomplete). It looks for venues by name near the map centre *and*
///   for addresses, and lists both.
/// * When the map stops moving, the address and the venues in view are looked
///   up after a short [debounce], so a drag produces one request, not
///   hundreds. A lookup that finishes after the map moved on is discarded.
/// * A failed lookup keeps the previous address, but the coordinates still
///   follow the map, so the user can always confirm. Venues are a bonus:
///   if they cannot be loaded nothing is shown and nothing breaks.
class LocationPickerCubit extends Cubit<LocationPickerState> {
  LocationPickerCubit({
    required GeocodingRepository geocoding,
    required VenuesRepository venues,
    required LocationService location,
    required LatLng initialCenter,
    String initialAddress = '',
    this.debounce = const Duration(milliseconds: 700),
  }) : _geocoding = geocoding,
       _venues = venues,
       _location = location,
       super(
         LocationPickerState(
           center: initialCenter,
           address: initialAddress,
           title: initialAddress.split(',').first.trim(),
           status: initialAddress.isEmpty
               ? LocationPickerStatus.idle
               : LocationPickerStatus.ready,
         ),
       );

  final GeocodingRepository _geocoding;
  final VenuesRepository _venues;
  final LocationService _location;
  final Duration debounce;

  /// Venues are only drawn when zoomed in enough to see individual streets.
  static const double minVenueZoom = 15;

  Timer? _timer;

  /// Identifies the latest lookup; older answers are dropped.
  int _lookup = 0;

  /// The map is being moved: the coordinates follow, no request is made yet.
  void mapMoving(LatLng center) {
    _timer?.cancel();
    _lookup++; // whatever is in flight is already outdated
    emit(
      state.copyWith(center: center, clearSelected: true, clearMessage: true),
    );
  }

  /// The user let go of the map: look up the address (and the venues in
  /// [viewport]) after [debounce].
  void mapMoved(LatLng center, {MapViewport? viewport}) {
    _timer?.cancel();
    _lookup++;
    emit(state.copyWith(center: center, clearSelected: true));
    _timer = Timer(debounce, () {
      _resolve(center);
      if (viewport != null && viewport.zoom >= minVenueZoom) {
        _loadVenues(viewport.bounds);
      }
    });
  }

  /// Loads the venues of the first view of the map (when the picker opens,
  /// or after the map is ready) without touching the address.
  void showVenuesIn(MapViewport viewport) {
    if (viewport.zoom >= minVenueZoom) _loadVenues(viewport.bounds);
  }

  Future<void> _resolve(LatLng center) async {
    final int mine = ++_lookup;
    emit(
      state.copyWith(
        status: LocationPickerStatus.resolving,
        clearMessage: true,
      ),
    );
    try {
      final GeocodingResult? found = await _geocoding.reverse(
        center.latitude,
        center.longitude,
      );
      if (isClosed || mine != _lookup) return;
      emit(
        found == null
            ? state.copyWith(status: LocationPickerStatus.idle)
            : state.copyWith(
                status: LocationPickerStatus.ready,
                title: found.title,
                address: found.displayName,
              ),
      );
    } on GeocodingFailure catch (failure) {
      if (isClosed || mine != _lookup) return;
      // Keep the previous address; the coordinates are already current.
      emit(
        state.copyWith(
          status: LocationPickerStatus.error,
          message: failure.message,
        ),
      );
    }
  }

  /// Fetches venues for the markers. Not part of [_lookup]: it does not
  /// block or cancel the address lookup, and its failure is ignored.
  Future<void> _loadVenues(GeoBounds bounds) async {
    try {
      final List<GeocodingResult> found = await _venues.nearby(bounds);
      if (!isClosed) emit(state.copyWith(venues: found));
    } on GeocodingFailure {
      // Markers are optional.
    }
  }

  /// Runs the typed search: venues with that name near the map centre, and
  /// addresses. One match centres the map on it; several are listed.
  Future<void> search(String query) async {
    final String q = query.trim();
    if (q.isEmpty) return;
    _timer?.cancel();
    final int mine = ++_lookup;
    emit(
      state.copyWith(
        status: LocationPickerStatus.searching,
        results: const [],
        clearMessage: true,
      ),
    );
    GeocodingFailure? failure;
    Future<List<GeocodingResult>> safe(
      Future<List<GeocodingResult>> call,
    ) async {
      try {
        return await call;
      } on GeocodingFailure catch (f) {
        failure = f;
        return const [];
      }
    }

    final List<List<GeocodingResult>> both = await Future.wait([
      safe(
        _venues.searchByName(
          q,
          latitude: state.center.latitude,
          longitude: state.center.longitude,
        ),
      ),
      safe(_geocoding.search(q)),
    ]);
    if (isClosed || mine != _lookup) return;

    final List<GeocodingResult> merged = _merge(both[0], both[1]);
    if (merged.isEmpty) {
      emit(
        state.copyWith(
          status: LocationPickerStatus.error,
          message: failure?.message ?? AppStrings.searchNoResults,
        ),
      );
    } else if (merged.length == 1) {
      _select(merged.first);
    } else {
      emit(state.copyWith(status: LocationPickerStatus.idle, results: merged));
    }
  }

  /// Venues first (they are what the user usually means), then addresses,
  /// without the same spot twice.
  static List<GeocodingResult> _merge(
    List<GeocodingResult> venues,
    List<GeocodingResult> addresses,
  ) {
    final List<GeocodingResult> out = [...venues.take(6)];
    for (final GeocodingResult a in addresses) {
      final bool duplicate = out.any(
        (GeocodingResult v) =>
            (v.latitude - a.latitude).abs() < 0.0003 &&
            (v.longitude - a.longitude).abs() < 0.0003,
      );
      if (!duplicate) out.add(a);
      if (out.length >= 8) break;
    }
    return out;
  }

  /// The user picked a listed match or tapped a venue marker.
  void selectResult(GeocodingResult result) => _select(result);

  void _select(GeocodingResult result) {
    _lookup++;
    emit(
      state.copyWith(
        center: LatLng(result.latitude, result.longitude),
        status: LocationPickerStatus.ready,
        title: result.title,
        address: result.displayName,
        results: const [],
        selected: result.isVenue ? result : null,
        clearSelected: !result.isVenue,
        clearMessage: true,
        recenter: true,
      ),
    );
    // Show what else is around the chosen spot.
    _loadVenues(GeoBounds.around(result.latitude, result.longitude));
  }

  /// "My location": reads the phone's position, moves the map there, names
  /// the spot and shows the venues around it.
  Future<void> useMyLocation() async {
    if (state.status == LocationPickerStatus.locating) return;
    _timer?.cancel();
    final int mine = ++_lookup;
    emit(
      state.copyWith(
        status: LocationPickerStatus.locating,
        results: const [],
        clearMessage: true,
      ),
    );
    try {
      final ({double latitude, double longitude}) here = await _location
          .currentPosition();
      if (isClosed || mine != _lookup) return;
      final LatLng point = LatLng(here.latitude, here.longitude);
      emit(
        state.copyWith(
          center: point,
          status: LocationPickerStatus.resolving,
          clearSelected: true,
          recenter: true,
        ),
      );
      _loadVenues(GeoBounds.around(here.latitude, here.longitude));
      await _resolve(point);
    } on LocationFailure catch (failure) {
      if (isClosed || mine != _lookup) return;
      emit(
        state.copyWith(
          status: LocationPickerStatus.error,
          message: failure.message,
        ),
      );
    }
  }

  /// Moves the map to a place whose address is known but whose coordinates
  /// are not (an old record). Quiet: finding nothing or failing is fine,
  /// the picker just stays on its default centre.
  Future<void> centerOnAddress(String address) async {
    final int mine = ++_lookup;
    try {
      final List<GeocodingResult> found = await _geocoding.search(address);
      if (isClosed || mine != _lookup || found.isEmpty) return;
      final GeocodingResult first = found.first;
      emit(
        state.copyWith(
          center: LatLng(first.latitude, first.longitude),
          recenter: true,
        ),
      );
    } on GeocodingFailure {
      // Ignored on purpose (see above).
    }
  }

  /// What the form receives. The address falls back to the coordinates when
  /// no address could be resolved (e.g. offline). A chosen venue also hands
  /// over its name and kind.
  PickedLocation get picked {
    final GeocodingResult? venue = state.selected;
    return PickedLocation(
      address: state.hasAddress
          ? state.address
          : '${state.center.latitude.toStringAsFixed(5)}, '
                '${state.center.longitude.toStringAsFixed(5)}',
      latitude: state.center.latitude,
      longitude: state.center.longitude,
      name: venue?.title,
      category: venue?.category,
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
