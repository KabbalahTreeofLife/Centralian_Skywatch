import 'json_utils.dart';

/// A single upcoming rocket launch from Launch Library 2.
///
/// Parsed from the `mode=list` response, which is flat: the agency, mission
/// type, pad and location arrive as plain strings rather than nested objects.
class Launch {
  const Launch({
    required this.id,
    required this.name,
    required this.statusName,
    required this.statusDescription,
    required this.agency,
    required this.missionType,
    required this.padName,
    required this.locationName,
    this.net,
    this.imageUrl,
  });

  final String id;
  final String name;

  /// No Earlier Than: the scheduled launch time in UTC.
  ///
  /// Null when the API has not published a time yet.
  final DateTime? net;

  final String statusName;
  final String statusDescription;
  final String agency;
  final String missionType;
  final String padName;
  final String locationName;

  /// Mission patch or rocket image, when the API provides one.
  final String? imageUrl;

  factory Launch.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> status = readMap(json['status']);
    return Launch(
      id: readString(json['id']),
      name: readString(json['name'], fallback: 'Unknown launch'),
      net: readDateTimeOrNull(json['net']),
      statusName: readString(status['name'], fallback: 'Unknown'),
      statusDescription: readString(status['description']),
      agency: readString(json['lsp_name'], fallback: 'Unknown agency'),
      missionType: readString(json['mission_type'], fallback: 'Unknown'),
      padName: readString(json['pad'], fallback: 'Unknown pad'),
      locationName: readString(json['location'], fallback: 'Unknown location'),
      imageUrl: readStringOrNull(json['image']),
    );
  }

  /// JSON snapshot used to restore this launch from the favorites list.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'net': net?.toIso8601String(),
    'status': <String, dynamic>{
      'name': statusName,
      'description': statusDescription,
    },
    'lsp_name': agency,
    'mission_type': missionType,
    'pad': padName,
    'location': locationName,
    'image': imageUrl,
  };
}
