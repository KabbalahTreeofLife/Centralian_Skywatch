import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:centralian_skywatch/models/favorite_item.dart';
import 'package:centralian_skywatch/models/launch.dart';
import 'package:centralian_skywatch/providers/favorites_provider.dart';
import 'package:centralian_skywatch/screens/launch_detail_screen.dart';

/// A launch with every field populated.
Launch _launch({DateTime? net}) => Launch(
  id: 'launch-1',
  name: 'Falcon 9 Block 5 | Starlink Group 15-15',
  net: net ?? DateTime.now().toUtc().add(const Duration(hours: 2)),
  statusName: 'Go for Launch',
  statusDescription: 'Current T-0 confirmed by official or reliable sources.',
  agency: 'SpaceX',
  missionType: 'Communications',
  padName: 'Space Launch Complex 4E',
  locationName: 'Vandenberg SFB, CA, USA',
  imageUrl: 'https://example.test/patch.png',
);

/// Pumps the detail screen with [launch] as the route argument.
Future<FavoritesProvider> pumpDetail(
  WidgetTester tester, {
  required Object? launch,
}) async {
  final FavoritesProvider favorites = FavoritesProvider();
  await favorites.load();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<FavoritesProvider>.value(value: favorites),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    settings: RouteSettings(arguments: launch),
                    builder: (_) => const LaunchDetailScreen(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  return favorites;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders the mission name and agency', (
    WidgetTester tester,
  ) async {
    await pumpDetail(tester, launch: _launch());

    expect(
      find.text('Falcon 9 Block 5 | Starlink Group 15-15'),
      findsOneWidget,
    );
    expect(find.text('SpaceX'), findsWidgets);
  });

  testWidgets('renders every detail the issue asks for', (
    WidgetTester tester,
  ) async {
    await pumpDetail(tester, launch: _launch());

    expect(find.text('Agency'), findsOneWidget);
    expect(find.text('Launch site'), findsOneWidget);
    expect(find.text('Vandenberg SFB, CA, USA'), findsOneWidget);
    expect(find.text('Pad'), findsOneWidget);
    expect(find.text('Space Launch Complex 4E'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.textContaining('Go for Launch'), findsWidgets);

    // The list is longer than the viewport, so the lower rows need scrolling.
    await tester.scrollUntilVisible(find.text('Mission type'), 200);
    expect(find.text('Mission type'), findsOneWidget);
    expect(find.text('Communications'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Launch time'), 200);
    expect(find.text('Launch time'), findsOneWidget);
  });

  testWidgets('shows a countdown for a launch that is close', (
    WidgetTester tester,
  ) async {
    await pumpDetail(tester, launch: _launch());

    expect(find.text('Launching in'), findsOneWidget);
    // Match the countdown's own shape, not the UTC time in the detail rows.
    expect(
      find.textContaining(RegExp(r'^T-\d{2}:\d{2}:\d{2}$')),
      findsOneWidget,
    );
  });

  testWidgets('shows the date when the launch is far out', (
    WidgetTester tester,
  ) async {
    await pumpDetail(
      tester,
      launch: _launch(
        net: DateTime.now().toUtc().add(const Duration(days: 30)),
      ),
    );

    expect(find.text('Scheduled for'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^T-\d{2}:\d{2}:\d{2}$')), findsNothing);
  });

  testWidgets('handles a launch with no scheduled time', (
    WidgetTester tester,
  ) async {
    await pumpDetail(
      tester,
      launch: Launch(
        id: 'launch-2',
        name: 'Unnamed',
        statusName: 'To Be Determined',
        statusDescription: '',
        agency: 'Unknown agency',
        missionType: 'Unknown',
        padName: 'Unknown pad',
        locationName: 'Unknown location',
      ),
    );

    expect(find.text('To be announced'), findsOneWidget);
    expect(find.textContaining('T-'), findsNothing);
  });

  testWidgets('shows a message when no launch was passed', (
    WidgetTester tester,
  ) async {
    await pumpDetail(tester, launch: null);

    expect(find.text('No launch was passed to this screen.'), findsOneWidget);
  });

  testWidgets('shows a message when the argument is the wrong type', (
    WidgetTester tester,
  ) async {
    await pumpDetail(tester, launch: 'not a launch');

    expect(find.text('No launch was passed to this screen.'), findsOneWidget);
  });

  testWidgets('the favorite button saves and unsaves the launch', (
    WidgetTester tester,
  ) async {
    final FavoritesProvider favorites = await pumpDetail(
      tester,
      launch: _launch(),
    );

    expect(find.text('Save to favorites'), findsOneWidget);

    await tester.tap(find.text('Save to favorites'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(favorites.contains(FavoriteType.launch, 'launch-1'), isTrue);
    expect(find.text('Saved to favorites'), findsOneWidget);

    await tester.tap(find.text('Saved to favorites'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(favorites.contains(FavoriteType.launch, 'launch-1'), isFalse);
    expect(find.text('Save to favorites'), findsOneWidget);
  });
}
