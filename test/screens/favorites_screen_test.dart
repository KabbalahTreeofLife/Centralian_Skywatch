import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:centralian_skywatch/models/favorite_item.dart';
import 'package:centralian_skywatch/providers/favorites_provider.dart';
import 'package:centralian_skywatch/screens/favorites_screen.dart';

const FavoriteItem _launch = FavoriteItem(
  id: 'a',
  type: FavoriteType.launch,
  title: 'Falcon 9 | Test',
);

/// Pumps the Favorites screen over a provider holding [items].
Future<FavoritesProvider> pumpScreen(
  WidgetTester tester, {
  List<FavoriteItem> items = const <FavoriteItem>[],
}) async {
  final FavoritesProvider provider = FavoritesProvider();
  await provider.load();
  for (final FavoriteItem item in items) {
    await provider.add(item);
  }

  await tester.pumpWidget(
    ChangeNotifierProvider<FavoritesProvider>.value(
      value: provider,
      child: const MaterialApp(home: FavoritesScreen()),
    ),
  );
  await tester.pumpAndSettle();

  return provider;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('shows the empty state when nothing is saved', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('No favorites yet.'), findsOneWidget);
  });

  testWidgets('lists a saved favorite with its note', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      items: <FavoriteItem>[
        const FavoriteItem(
          id: '2026-10-22',
          type: FavoriteType.apod,
          title: 'NASA Science',
          note: 'Look up',
        ),
      ],
    );

    expect(find.text('NASA Science'), findsOneWidget);
    expect(find.text('Look up'), findsOneWidget);
    expect(find.text('No favorites yet.'), findsNothing);
  });

  testWidgets('shows "No note" when the note is empty', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, items: <FavoriteItem>[_launch]);

    expect(find.text('No note'), findsOneWidget);
  });

  testWidgets('delete asks for confirmation and removes the item', (
    WidgetTester tester,
  ) async {
    final FavoritesProvider provider = await pumpScreen(
      tester,
      items: <FavoriteItem>[_launch],
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Remove favorite?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(provider.isEmpty, isTrue);
    expect(find.text('No favorites yet.'), findsOneWidget);
  });

  testWidgets('cancelling the delete keeps the item', (
    WidgetTester tester,
  ) async {
    final FavoritesProvider provider = await pumpScreen(
      tester,
      items: <FavoriteItem>[_launch],
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(provider.count, 1);
    expect(find.text('Falcon 9 | Test'), findsOneWidget);
  });

  testWidgets('the note dialog rejects an empty note', (
    WidgetTester tester,
  ) async {
    final FavoritesProvider provider = await pumpScreen(
      tester,
      items: <FavoriteItem>[_launch],
    );

    await tester.tap(find.text('Falcon 9 | Test'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Note cannot be empty'), findsOneWidget);
    expect(provider.items.single.note, isEmpty);
  });

  testWidgets('the note dialog saves a valid note', (
    WidgetTester tester,
  ) async {
    final FavoritesProvider provider = await pumpScreen(
      tester,
      items: <FavoriteItem>[_launch],
    );

    await tester.tap(find.text('Falcon 9 | Test'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Watch the replay');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(provider.items.single.note, 'Watch the replay');
    expect(find.text('Watch the replay'), findsOneWidget);
  });

  testWidgets('the note dialog caps the note at 200 characters', (
    WidgetTester tester,
  ) async {
    final FavoritesProvider provider = await pumpScreen(
      tester,
      items: <FavoriteItem>[_launch],
    );

    await tester.tap(find.text('Falcon 9 | Test'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'a' * 250);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(provider.items.single.note.length, 200);
  });
}
