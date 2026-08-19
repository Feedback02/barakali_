/// The 4px spacing grid from the design system, encoded so layout rhythm is
/// consistent instead of hand-rolled per screen. Adopt incrementally — prefer
/// these over raw `SizedBox`/`EdgeInsets` magic numbers in new and touched code.
abstract final class AppSpacing {
  /// 4px — hairline gaps (icon ↔ label).
  static const double xs = 4;

  /// 8px — tight grouping inside a component.
  static const double sm = 8;

  /// 12px — default gap between related elements; also the brand radius.
  static const double md = 12;

  /// 16px — standard screen / card padding.
  static const double lg = 16;

  /// 24px — section separation.
  static const double xl = 24;

  /// 32px — major block separation.
  static const double xxl = 32;

  /// The design-system corner radius (12px).
  static const double radius = 12;
}
