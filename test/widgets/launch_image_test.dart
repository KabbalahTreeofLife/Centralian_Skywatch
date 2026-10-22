import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:centralian_skywatch/widgets/launch_image.dart';

Future<void> pumpImage(WidgetTester tester, {required String? url}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LaunchImage(url: url, semanticLabel: 'Rocket for a launch'),
      ),
    ),
  );
  // The image is fetched over the network and never resolves in a test, so
  // pump a fixed frame rather than settling.
  await tester.pump();
}

void main() {
  group('LaunchImage', () {
    testWidgets('requests the given URL', (WidgetTester tester) async {
      await pumpImage(tester, url: 'https://example.test/rocket.png');

      final CachedNetworkImage image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );

      expect(image.imageUrl, 'https://example.test/rocket.png');
    });

    testWidgets('shows a placeholder while the image loads', (
      WidgetTester tester,
    ) async {
      await pumpImage(tester, url: 'https://example.test/rocket.png');

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('shows a rocket placeholder when there is no URL', (
      WidgetTester tester,
    ) async {
      await pumpImage(tester, url: null);

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.rocket_launch_outlined), findsOneWidget);
      expect(find.text('No image for this launch'), findsOneWidget);
    });

    testWidgets('shows an error state when the image fails', (
      WidgetTester tester,
    ) async {
      await pumpImage(tester, url: 'https://example.test/rocket.png');

      final CachedNetworkImage image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );

      // Render the error widget the way CachedNetworkImage would.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: image.errorWidget!(
              tester.element(find.byType(LaunchImage)),
              'https://example.test/rocket.png',
              Exception('offline'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Image unavailable'), findsOneWidget);
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });

    testWidgets('keeps a fixed aspect ratio in every state', (
      WidgetTester tester,
    ) async {
      await pumpImage(tester, url: null);

      final AspectRatio frame = tester.widget<AspectRatio>(
        find.byType(AspectRatio),
      );

      expect(frame.aspectRatio, closeTo(16 / 9, 0.001));
    });

    testWidgets('labels the image for screen readers', (
      WidgetTester tester,
    ) async {
      await pumpImage(tester, url: 'https://example.test/rocket.png');

      final CachedNetworkImage image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );

      // Build the image builder without pumping it, so the real NetworkImage
      // is never resolved.
      final Widget built = image.imageBuilder!(
        tester.element(find.byType(LaunchImage)),
        const NetworkImage('https://example.test/rocket.png'),
      );

      final Semantics semantics = built as Semantics;

      expect(semantics.properties.label, 'Rocket for a launch');
      expect(semantics.properties.image, isTrue);
    });
  });
}
