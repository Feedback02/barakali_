import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:barakali/core/constants/app_constants.dart';

/// Cached network image with a neutral placeholder and an icon fallback for
/// missing/failed URLs. Clips to the app's standard corner radius.
class BarakaliImage extends StatelessWidget {
  const BarakaliImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String? url;
  final double? width;
  final double? height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(
      borderRadius ?? AppConstants.borderRadius,
    );

    Widget neutral({bool showIcon = false}) => Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: showIcon
          ? Icon(
              Icons.image_rounded,
              color: scheme.onSurface.withValues(alpha: 0.3),
            )
          : null,
    );

    return ClipRRect(
      borderRadius: radius,
      child: (url == null || url!.isEmpty)
          ? neutral(showIcon: true)
          : CachedNetworkImage(
              imageUrl: url!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholder: (_, _) => neutral(),
              errorWidget: (_, _, _) => neutral(showIcon: true),
            ),
    );
  }
}
