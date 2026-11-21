/// `40.7587° N, 73.9787° W` — four decimals, hemisphere letters instead of
/// minus signs (as in the design of the location picker).
String formatCoordinates(double latitude, double longitude) {
  final String lat =
      '${latitude.abs().toStringAsFixed(4)}° ${latitude >= 0 ? 'N' : 'S'}';
  final String lon =
      '${longitude.abs().toStringAsFixed(4)}° ${longitude >= 0 ? 'E' : 'W'}';
  return '$lat, $lon';
}
