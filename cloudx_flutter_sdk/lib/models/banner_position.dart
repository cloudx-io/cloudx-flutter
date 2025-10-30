/// Position for programmatic ad view placement
library;

/// Represents where a programmatic ad view should be positioned on screen.
///
/// Programmatic ad views are positioned as native overlays on top of Flutter content,
/// rather than being embedded in the Flutter widget tree. This allows for sticky
/// ads that stay fixed while content scrolls underneath.
///
/// Can be used with banners, MRECs, and other ad view types.
enum AdViewPosition {
  /// Top center of the screen
  topCenter('top_center'),

  /// Top right of the screen
  topRight('top_right'),

  /// Center of the screen
  centered('centered'),

  /// Center left of the screen
  centerLeft('center_left'),

  /// Center right of the screen
  centerRight('center_right'),

  /// Bottom left of the screen
  bottomLeft('bottom_left'),

  /// Bottom center of the screen
  bottomCenter('bottom_center'),

  /// Bottom right of the screen
  bottomRight('bottom_right');

  /// Internal value for platform channel communication
  final String value;

  const AdViewPosition(this.value);
}
