/// Arguments of the `AppRoutes.placeDetails` route.
///
/// Only the id travels: the screen reads the current place from
/// `PlacesBloc`, so it always shows the latest data and needs no callbacks.
class PlaceDetailsArgs {
  const PlaceDetailsArgs({required this.placeId});

  final String placeId;
}
