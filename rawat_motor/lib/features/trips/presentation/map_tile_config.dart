abstract final class MapTileConfig {
  static const tileUrlTemplate = String.fromEnvironment('MAP_TILE_URL');
  static const userAgentPackageName = String.fromEnvironment(
    'MAP_USER_AGENT_PACKAGE',
    defaultValue: 'id.rawatin.app',
  );
  static const attribution = String.fromEnvironment(
    'MAP_ATTRIBUTION',
    defaultValue: '© OpenStreetMap contributors',
  );
  static const developmentUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static String? get configuredUrl =>
      tileUrlTemplate.isEmpty ? null : tileUrlTemplate;
}
