import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';

import '../../data/models/place_photo.dart';
import '../theme/app_colors.dart';

/// The one widget that shows a [PlacePhoto], whatever its origin:
/// bundled asset, a file on this device, or an uploaded photo.
///
/// Having a single place that knows the three cases keeps cards, the details
/// hero, the form and the gallery identical, and a new origin only needs
/// handling here. Network photos get a placeholder while loading and an
/// error tile if the URL cannot be fetched (offline, deleted file).
class PlaceImageView extends StatelessWidget {
  const PlaceImageView({
    super.key,
    required this.photo,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final PlacePhoto photo;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Tests replace the network branch: `cached_network_image` needs a
  /// database and a real HTTP client, which unit tests must not touch.
  @visibleForTesting
  static Widget Function(String url)? debugRemoteBuilder;

  @override
  Widget build(BuildContext context) {
    switch (photo.kind) {
      case PhotoKind.asset:
        return Image.asset(
          photo.location,
          width: width,
          height: height,
          fit: fit,
        );
      case PhotoKind.local:
        return Image.file(
          File(photo.location),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => const _PhotoFallback(),
        );
      case PhotoKind.remote:
        final Widget Function(String)? override = debugRemoteBuilder;
        if (override != null) return override(photo.location);
        return CachedNetworkImage(
          imageUrl: photo.location,
          width: width,
          height: height,
          fit: fit,
          placeholder: (_, _) => const _PhotoPlaceholder(),
          errorWidget: (_, _, _) => const _PhotoFallback(),
        );
    }
  }
}

/// Grey tile with a spinner while a network photo loads.
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceContainer,
      child: Center(child: CupertinoActivityIndicator()),
    );
  }
}

/// Grey tile with a picture icon when the photo cannot be shown.
class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceContainer,
      child: Center(
        child: Icon(CupertinoIcons.photo, color: AppColors.textTertiary),
      ),
    );
  }
}
