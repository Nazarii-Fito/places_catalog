import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders an icon exported from Figma as SVG.
///
/// The SVG keeps its intrinsic Figma size unless [width]/[height] are given.
/// Pass [color] to tint single-colour icons (e.g. active/inactive tabs).
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(
    this.asset, {
    super.key,
    this.color,
    this.width,
    this.height,
  });

  final String asset;
  final Color? color;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final Color? tint = color;
    return SvgPicture.asset(
      asset,
      width: width,
      height: height,
      colorFilter: tint == null
          ? null
          : ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}
