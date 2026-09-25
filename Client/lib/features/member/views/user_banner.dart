import 'package:bonfire/theme/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A 16:9 profile banner. [url] is already absolute.
class UserBannerImage extends StatelessWidget {
  const UserBannerImage({
    super.key,
    required this.url,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final String url;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return ClipRRect(
      borderRadius: borderRadius,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : 320.0;
          final height = width * 9 / 16;
          return SizedBox(
            width: width,
            height: height,
            child: ColoredBox(
              color: colors.darkGray,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: width,
                height: height,
                errorWidget: (_, _, _) => Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: colors.gray,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
