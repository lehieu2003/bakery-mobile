/// Spacing scale on a 4px grid (plus [xxs] for hairline gaps).
///
/// Use for padding/margins (`EdgeInsets.all(AppSpacing.lg)`), gaps between
/// siblings (`Gap(AppSpacing.md)` from package:gap) and `spacing:` params.
/// Never write a raw number for spacing; if a layout needs a value off the
/// scale, it is a fixed size (e.g. a nav-bar clearance), not spacing — name it
/// where it is used.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double x3l = 32;
  static const double x4l = 40;
  static const double x5l = 48;
}
