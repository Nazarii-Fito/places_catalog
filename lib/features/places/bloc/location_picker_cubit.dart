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

enum LocationPickerStatus {
  /// Nothing is running; the card shows the current point.
  idle,

  /// An address search (submitted text) is running.
  searching,

  /// The address of the map centre is being looked up.
  resolving,

  /// The card shows a resolved address for the current point.
  ready,

  /// A search or lookup failed; [LocationPickerState.message] says why.
  error,
}

class LocationPickerState extends Equatable {
  const LocationPickerState({
    required this.center,
    this.status = LocationPickerStatus.idle,
    this.title = '',
    this.address = '',
    this.results = const [],
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
  final String? message;

  /// Increments when the *cubit* wants the map to jump to [center] (after a
  /// search); a drag by the user does not change it. The screen moves the
  /// map controller when it changes, which avoids a feedback loop.
  final int recenterTick;

  bool get hasAddress => address.isNotEmpty;

  LocationPickerState copyWith({
    LatLng? center,
    LocationPickerStatus? status,
    String? title,
    String? address,
    List<GeocodingResult>? results,
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
    message,
    recenterTick,
  ];
}

/// State of the location picker: search, the point under the pin and its
/// address.
///
/// * Search happens **on submit** only (Nominatim forbids autocomplete).
/// * When the map stops moving, the address is looked up after a short
///   [debounce], so a drag produces one request, not hundreds. A lookup that
///   finishes after the map moved on again is discarded.
/// * A failed lookup keeps the previous address, but the coordinates still
///   follow the map, so the user can always confirm.
class LocationPickerCubit extends Cubit<LocationPickerState> {
  LocationPickerCubit({
    required GeocodingRepository geocoding,
    required LatLng initialCenter,
    String initialAddress = '',
    this.debounce = const Duration(milliseconds: 700),
  }) : _geocoding = geocoding,
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
  final Duration debounce;

  Timer? _timer;

  /// Identifies the latest lookup; older answers are dropped.
  int _lookup = 0;

  /// The map is being moved: the coordinates follow, no request is made yet.
  void mapMoving(LatLng center) {
    _timer?.cancel();
    _lookup++; // whatever is in flight is already outdated
    emit(state.copyWith(center: center, clearMessage: true));
  }

  /// The user let go of the map: look up the address after [debounce].
  void mapMoved(LatLng center) {
    _timer?.cancel();
    _lookup++;
    emit(state.copyWith(center: center));
    _timer = Timer(debounce, () => _resolve(center));
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

  /// Runs the typed search. One match centres the map on it; several are
  /// listed so the user can choose.
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
    try {
      final List<GeocodingResult> found = await _geocoding.search(q);
      if (isClosed || mine != _lookup) return;
      if (found.isEmpty) {
        emit(
          state.copyWith(
            status: LocationPickerStatus.error,
            message: AppStrings.searchNoResults,
          ),
        );
      } else if (found.length == 1) {
        _select(found.first);
      } else {
        emit(state.copyWith(status: LocationPickerStatus.idle, results: found));
      }
    } on GeocodingFailure catch (failure) {
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

  /// The user picked one of the listed matches.
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
        clearMessage: true,
        recenter: true,
      ),
    );
  }

  /// What the form receives. The address falls back to the coordinates when
  /// no address could be resolved (e.g. offline).
  PickedLocation get picked => PickedLocation(
    address: state.hasAddress
        ? state.address
        : '${state.center.latitude.toStringAsFixed(5)}, '
              '${state.center.longitude.toStringAsFixed(5)}',
    latitude: state.center.latitude,
    longitude: state.center.longitude,
  );

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
