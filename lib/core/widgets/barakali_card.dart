import 'package:flutter/material.dart';

import 'package:barakali/core/constants/app_constants.dart';

/// A rounded surface container used for offer/merchant/order cards. Optionally
/// tappable.
class BarakaliCard extends StatelessWidget {
  const BarakaliCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppConstants.defaultPadding),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppConstants.borderRadius);

    return Material(
      color: scheme.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
