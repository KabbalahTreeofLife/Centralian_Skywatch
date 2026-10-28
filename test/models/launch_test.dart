import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:centralian_skywatch/models/launch.dart';

/// A real `mode=list` response captured from Launch Library 2.
const String _sampleJson = '''
{
  "id": "f6af629d-39b5-4f86-bc0c-f8776444a858",
  "url": "https://ll.thespacedevs.com/2.2.0/launch/f6af629d-39b5-4f86-bc0c-f8776444a858/",
  "slug": "falcon-9-block-5-starlink-group-15-15",
  "name": "Falcon 9 Block 5 | Starlink Group 15-15",
  "status": {
    "id": 1,
    "name": "Go for Launch",
    "abbrev": "Go",
    "description": "Current T-0 confirmed by official or reliable sources."
  },
  "last_updated": "2026-10-22T15:20:15Z",
  "net": "2026-10-22T22:51:18Z",
  "net_precision": {
    "id": 0,
    "name": "Second",
    "abbrev": "SEC",
    "description": "The T-0 is accurate to the second."
  },
  "window_end": "2026-10-23T01:45:00Z",
  "window_start": "2026-10-22T21:45:00Z",
  "lsp_name": "SpaceX",
  "mission": "Starlink Group 15-15",
  "mission_type": "Communications",
  "pad": "Space Launch Complex 4E",
  "location": "Vandenberg SFB, CA, USA",
  "landing": null,
  "landing_success": null,
  "launcher": null,
  "orbit": null,
  "image": "https://thespacedevs-prod.nyc3.digitaloceanspaces.com/media/images/falcon2520925_image_20221009234147.png",
  "infographic": null,
  "type": "list"
}
''';

void main() {
  group('Launch.fromJson', () {
    test('parses a real mode=list response', () {
      final Launch launch = Launch.fromJson(
        jsonDecode(_sampleJson) as Map<String, dynamic>,
      );

      expect(launch.id, 'f6af629d-39b5-4f86-bc0c-f8776444a858');
      expect(launch.name, 'Falcon 9 Block 5 | Starlink Group 15-15');
      expect(launch.net, DateTime.utc(2026, 10, 22, 22, 51, 18));
      expect(launch.net!.isUtc, isTrue);
      expect(launch.statusName, 'Go for Launch');
      expect(launch.statusDescription, contains('T-0'));
      expect(launch.agency, 'SpaceX');
      expect(launch.missionType, 'Communications');
      expect(launch.padName, 'Space Launch Complex 4E');
      expect(launch.locationName, 'Vandenberg SFB, CA, USA');
      expect(launch.imageUrl, startsWith('https://'));
    });

    test('survives missing and null fields', () {
      final Launch launch = Launch.fromJson(<String, dynamic>{
        'id': null,
        'name': null,
        'net': null,
        'status': null,
        'lsp_name': null,
        'mission_type': null,
        'pad': null,
        'location': null,
        'image': null,
      });

      expect(launch.id, '');
      expect(launch.name, 'Unknown launch');
      expect(launch.net, isNull);
      expect(launch.statusName, 'Unknown');
      expect(launch.statusDescription, '');
      expect(launch.agency, 'Unknown agency');
      expect(launch.missionType, 'Unknown');
      expect(launch.padName, 'Unknown pad');
      expect(launch.locationName, 'Unknown location');
      expect(launch.imageUrl, isNull);
    });

    test('treats an invalid net as unknown instead of throwing', () {
      final Launch launch = Launch.fromJson(<String, dynamic>{
        'net': 'not-a-date',
      });

      expect(launch.net, isNull);
    });

    test('round-trips through the favorites detail snapshot', () {
      final Launch original = Launch.fromJson(
        jsonDecode(_sampleJson) as Map<String, dynamic>,
      );

      final Launch restored = Launch.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.net, original.net);
      expect(restored.statusName, original.statusName);
      expect(restored.statusDescription, original.statusDescription);
      expect(restored.agency, original.agency);
      expect(restored.missionType, original.missionType);
      expect(restored.padName, original.padName);
      expect(restored.locationName, original.locationName);
      expect(restored.imageUrl, original.imageUrl);
    });
  });
}
