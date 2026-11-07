import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/trip_point.dart';
import '../map_tile_config.dart';

class TripMap extends StatelessWidget {
  const TripMap({
    required this.points,
    this.current,
    this.fitRoute = false,
    super.key,
  });

  final List<TripPoint> points;
  final TripPoint? current;
  final bool fitRoute;

  @override
  Widget build(BuildContext context) {
    final shown = [...points, ?current];
    final route = shown.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final center = route.isNotEmpty
        ? route.last
        : const LatLng(-6.2088, 106.8456);
    final markers = <Marker>[];
    if (route.isNotEmpty) {
      markers.add(_flag(route.first, 'S', AppPalette.accent));
      if (route.length > 1)
        markers.add(_flag(route.last, 'F', AppPalette.primaryBright));
    }
    if (current != null) {
      markers.add(
        Marker(
          point: LatLng(current!.latitude, current!.longitude),
          width: 22,
          height: 22,
          child: Container(
            decoration: BoxDecoration(
              color: AppPalette.accent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 8),
              ],
            ),
          ),
        ),
      );
    }
    final url = MapTileConfig.configuredUrl ?? MapTileConfig.developmentUrl;
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15,
            minZoom: 3,
            maxZoom: 19,
            initialCameraFit: fitRoute && route.length > 1
                ? CameraFit.coordinates(
                    coordinates: route,
                    padding: const EdgeInsets.all(40),
                  )
                : null,
          ),
          children: [
            TileLayer(
              urlTemplate: url,
              userAgentPackageName: MapTileConfig.userAgentPackageName,
              tileBuilder: (context, child, tile) => ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0.25,
                  0,
                  0,
                  0,
                  0,
                  0,
                  0.28,
                  0,
                  0,
                  0,
                  0,
                  0,
                  0.34,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: child,
              ),
            ),
            if (route.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: route,
                    color: AppPalette.primaryBright,
                    strokeWidth: 7,
                  ),
                ],
              ),
            MarkerLayer(markers: markers),
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomRight,
              attributions: [TextSourceAttribution(MapTileConfig.attribution)],
            ),
          ],
        ),
        if (MapTileConfig.configuredUrl == null)
          const Positioned(
            top: 8,
            left: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  'Peta pengembangan',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Marker _flag(LatLng point, String label, Color color) => Marker(
    point: point,
    width: 38,
    height: 46,
    child: Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Container(width: 3, height: 14, color: Colors.white),
      ],
    ),
  );
}
