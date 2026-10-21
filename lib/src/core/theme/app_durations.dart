/// Motion and timing tokens. Use these instead of inline `Duration(...)`
/// literals so the same kind of movement feels the same everywhere.
abstract final class AppDurations {
  /// Micro interactions: chip/tab selection, small fades and scrolls.
  static const Duration fast = Duration(milliseconds: 200);

  /// Page and carousel transitions.
  static const Duration medium = Duration(milliseconds: 280);

  /// Intro/splash fades.
  static const Duration slow = Duration(milliseconds: 650);

  /// One loop of the skeleton shimmer.
  static const Duration shimmerCycle = Duration(milliseconds: 1200);

  /// Auto-advance interval of image carousels (home banner, product images).
  static const Duration carouselAutoplay = Duration(seconds: 2);

  /// Wait after the last keystroke before running a search request.
  static const Duration searchDebounce = Duration(milliseconds: 350);
}
