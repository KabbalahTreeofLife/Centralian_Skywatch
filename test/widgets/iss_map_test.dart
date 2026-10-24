import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:centralian_skywatch/models/iss_position.dart';
import 'package:centralian_skywatch/widgets/iss_map.dart';

IssPosition _position({double latitude = 51.64, double longitude = -0.28}) =>
    IssPosition(
      latitude: latitude,
      longitude: longitude,
      altitude: 420.5,
      speedKmh: 27580.4,
    );

Future<void> pumpMap(WidgetTester tester, IssPosition position) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(height: 400, child: IssMap(position: position)),
      ),
    ),
  );
  // Tiles are fetched over the network and never resolve in a test, so pump a
  // fixed frame rather than settling.
  await tester.pump();
}

/// The camera the map is currently showing.
MapCamera currentCamera(WidgetTester tester) =>
    MapCamera.of(tester.element(find.byType(MarkerLayer)));

/// The tile layer the map is configured with.
TileLayer tileLayer(WidgetTester tester) =>
    tester.widget<TileLayer>(find.byType(TileLayer));

void main() {
  group('IssMap', () {
    testWidgets('renders a map with a marker', (WidgetTester tester) async {
      await pumpMap(tester, _position());

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(MarkerLayer), findsOneWidget);
      expect(find.byIcon(Icons.satellite_alt), findsOneWidget);
    });

    testWidgets('places the marker at the reported position', (
      WidgetTester tester,
    ) async {
      await pumpMap(tester, _position(latitude: -33.87, longitude: 139.69));

      final MarkerLayer layer = tester.widget<MarkerLayer>(
        find.byType(MarkerLayer),
      );
      final Marker marker = layer.markers.single;

      expect(marker.point.latitude, -33.87);
      expect(marker.point.longitude, 139.69);
    });

    testWidgets('centres the map on the position', (WidgetTester tester) async {
      await pumpMap(tester, _position(latitude: 12.34, longitude: 56.78));

      final FlutterMap map = tester.widget<FlutterMap>(find.byType(FlutterMap));

      expect(map.options.initialCenter.latitude, 12.34);
      expect(map.options.initialCenter.longitude, 56.78);
    });

    testWidgets('follows the station when the position changes', (
      WidgetTester tester,
    ) async {
      // initialCenter is only read when the map is created, so without a
      // controller the marker would move while the camera stayed behind.
      await pumpMap(tester, _position(latitude: 10, longitude: -20));
      await pumpMap(tester, _position(latitude: -30, longitude: 60));
      // The camera moves in a post-frame callback, so give it one more frame.
      await tester.pump();

      final MapCamera camera = currentCamera(tester);

      expect(camera.center.latitude, closeTo(-30, 0.01));
      expect(camera.center.longitude, closeTo(60, 0.01));
    });

    testWidgets('keeps the zoom when it follows the station', (
      WidgetTester tester,
    ) async {
      await pumpMap(tester, _position(latitude: 10, longitude: -20));
      final double before = currentCamera(tester).zoom;

      await pumpMap(tester, _position(latitude: -30, longitude: 60));
      await tester.pump();

      expect(currentCamera(tester).zoom, before);
    });

    group('OpenStreetMap tile policy', () {
      testWidgets('uses the exact tile URL the policy requires', (
        WidgetTester tester,
      ) async {
        await pumpMap(tester, _position());

        expect(
          tileLayer(tester).urlTemplate,
          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        );
      });

      testWidgets('sends no subdomains, so the bare host is used', (
        WidgetTester tester,
      ) async {
        await pumpMap(tester, _position());

        // The TileLayer default is ['a', 'b', 'c'], which would hit
        // a.tile.openstreetmap.org — a host the policy says may be withdrawn.
        expect(tileLayer(tester).subdomains, isEmpty);
      });

      testWidgets('identifies the app in the User-Agent', (
        WidgetTester tester,
      ) async {
        await pumpMap(tester, _position());

        final String agent =
            tileLayer(tester).tileProvider.headers['User-Agent'] ?? '';

        expect(agent, contains('com.centralianskywatch.app'));
        expect(agent, isNot(contains('unknown')));
      });

      testWidgets('shows attribution on the map', (WidgetTester tester) async {
        await pumpMap(tester, _position());

        expect(find.byType(RichAttributionWidget), findsOneWidget);
        expect(find.textContaining('OpenStreetMap'), findsOneWidget);
      });
    });

    testWidgets('wires up a tile error callback for the fallback', (
      WidgetTester tester,
    ) async {
      await pumpMap(tester, _position());

      // The map cannot render tiles in a test, so the fallback is exercised
      // through the notice widget itself (below) and by asserting the layer
      // is configured to report failures.
      expect(tileLayer(tester).errorTileCallback, isNotNull);
    });

    testWidgets('the fallback notice explains the situation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(children: <Widget>[TilesUnavailableNotice()]),
          ),
        ),
      );

      expect(find.textContaining('Map tiles unavailable'), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    });
  });
}
