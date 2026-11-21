import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// OpenStreetMap raster tiles for `flutter_map`.
///
/// The tile server's policy requires an identifying `User-Agent` (taken
/// from [packageName], the app id) and visible credit — see
/// [OsmAttribution], which every map screen must show.
///
/// Tiles are only fetched when [useNetworkTiles] is on. `main.dart` turns it
/// on for a normal run; tests and the screenshot mode leave it off, so they
/// stay offline and deterministic: the map is then just a plain background.
class OsmTileLayer extends StatelessWidget {
  const OsmTileLayer({super.key});

  /// Off by default so no test can reach the network by accident.
  static bool useNetworkTiles = false;

  static const String packageName = 'ua.lpnu.pz33.placesCatalog';
  static const String urlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Plain colour behind (and instead of) the tiles.
  static const Color background = AppColors.surfaceContainer;

  @override
  Widget build(BuildContext context) {
    if (!useNetworkTiles) return const SizedBox.shrink();
    return TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: packageName,
    );
  }
}

/// "© OpenStreetMap contributors" — the credit the data licence (ODbL) and
/// the tile usage policy ask for. Small, but always visible on a map.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  static const String text = '© OpenStreetMap contributors';

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.tabLabel.copyWith(color: AppColors.textSecondary),
    );
  }
}
