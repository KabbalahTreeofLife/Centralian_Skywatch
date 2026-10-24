import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/iss_position.dart';

/// The map showing where the station is right now.
///
/// Tiles come from OpenStreetMap, whose tile usage policy sets four rules this
/// widget follows:
///
/// * The URL is exactly `https://tile.openstreetmap.org/{z}/{x}/{y}.png`, with
///   no subdomains. [TileLayer] defaults to `['a', 'b', 'c']`, which would hit
///   `a.tile.openstreetmap.org` — a host the policy says may be withdrawn.
/// * The User-Agent names the app, so the traffic is identifiable.
/// * Attribution is shown on the map, not hidden behind a toggle.
/// * Nothing is prefetched: only the tiles for the visible viewport load.
///
/// When tiles cannot be fetched the map falls back to a plain background and
/// keeps the marker, so the position is still readable offline.
class IssMap extends StatefulWidget {
  const IssMap({super.key, required this.position});

  final IssPosition position;

  @override
  State<IssMap> createState() => _IssMapState();
}

class _IssMapState extends State<IssMap> {
  /// Set once a tile fails, which switches the map to its fallback background.
  bool _tilesFailed = false;

  /// Lets the map follow the station.
  ///
  /// `MapOptions.initialCenter` is read once, when the map is created, so a
  /// later position would move the marker but not the camera. The station
  /// covers about 7.7 km every second, so without this it drifts out of view
  /// after a few refreshes.
  final MapController _controller = MapController();

  @override
  void didUpdateWidget(IssMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new position is a fresh attempt, so let the tiles be tried again.
    if (oldWidget.position.latitude != widget.position.latitude ||
        oldWidget.position.longitude != widget.position.longitude) {
      _tilesFailed = false;

      final LatLng point = LatLng(
        widget.position.latitude,
        widget.position.longitude,
      );
      // Moving the camera while the tree is rebuilding would ask the map to
      // rebuild itself mid-build, so wait for the frame to finish. The zoom is
      // kept, so a reader who zoomed in stays zoomed in.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.move(point, _controller.camera.zoom);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final LatLng point = LatLng(
      widget.position.latitude,
      widget.position.longitude,
    );

    return Stack(
      children: <Widget>[
        if (_tilesFailed)
          Container(color: theme.colorScheme.surfaceContainerHighest),
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: point,
            initialZoom: 3,
            minZoom: 1,
            maxZoom: 18,
            // Keep the map on the globe rather than letting it pan into blank
            // space, which also stops the marker drifting off-screen.
            cameraConstraint: CameraConstraint.contain(
              bounds: LatLngBounds(
                const LatLng(-85, -180),
                const LatLng(85, 180),
              ),
            ),
          ),
          children: <Widget>[
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              // The policy requires the bare host; the default subdomains
              // would produce a.tile.openstreetmap.org.
              subdomains: const <String>[],
              userAgentPackageName: 'com.centralianskywatch.app',
              maxNativeZoom: 19,
              errorTileCallback: (_, _, _) {
                if (!mounted || _tilesFailed) return;
                setState(() => _tilesFailed = true);
              },
            ),
            MarkerLayer(
              markers: <Marker>[
                Marker(
                  point: point,
                  width: 48,
                  height: 48,
                  child: _IssMarker(),
                ),
              ],
            ),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomRight,
              attributions: <SourceAttribution>[
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: null,
                ),
              ],
            ),
          ],
        ),
        if (_tilesFailed) const TilesUnavailableNotice(),
      ],
    );
  }
}

/// The station's marker: a satellite icon in a filled circle.
class _IssMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.onPrimary, width: 2),
      ),
      child: Icon(
        Icons.satellite_alt,
        size: 24,
        color: theme.colorScheme.onPrimary,
      ),
    );
  }
}

/// Shown over the map when the tiles could not be loaded.
///
/// The marker stays visible underneath, so the position is still usable.
@visibleForTesting
class TilesUnavailableNotice extends StatelessWidget {
  const TilesUnavailableNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Positioned(
      left: 12,
      right: 12,
      top: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.map_outlined,
              size: 18,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Map tiles unavailable — showing the position only.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
