import 'package:flutter/widgets.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/app_svg_icon.dart';

/// Five tappable stars (1–5). Stateless: the value lives in the parent
/// form and changes are reported via [onChanged].
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: List<Widget>.generate(5, (int index) {
        final int star = index + 1;
        return Semantics(
          button: true,
          selected: star <= value,
          label: '$star',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(star),
            child: SizedBox.square(
              dimension: 32,
              child: Center(
                child: AppSvgIcon(
                  star <= value ? AppAssets.iconStar : AppAssets.iconStarEmpty,
                  width: 18.333,
                  height: 17.417,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
