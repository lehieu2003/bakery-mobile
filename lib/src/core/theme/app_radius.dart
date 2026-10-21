/// Corner radius scale. Use with `BorderRadius.circular(AppRadius.md)` /
/// `Radius.circular(AppRadius.md)` instead of inline numbers.
abstract final class AppRadius {
  /// Small thumbnails.
  static const double xs = 8;

  /// List-tile thumbnails, compact chips.
  static const double sm = 10;

  /// Inputs, buttons, standard cards.
  static const double md = 12;

  static const double lg = 14;

  static const double xl = 16;

  /// Hero images, banners, prominent cards.
  static const double xxl = 18;

  static const double xxxl = 22;

  /// Large sheets and the auth card.
  static const double sheet = 28;

  /// Fully rounded ends (pills, badges, circular buttons).
  static const double pill = 999;
}
