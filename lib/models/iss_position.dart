import 'json_utils.dart';

/// The International Space Station's position at a point in time.
///
/// Parsed from Where the ISS at?, which reports `velocity` in km/h and
/// `timestamp` as Unix seconds.
class IssPosition {
  const IssPosition({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speedKmh,
    this.timestamp,
  });

  final double latitude;
  final double longitude;

  /// Altitude above sea level in kilometres.
  final double altitude;

  /// Ground speed in kilometres per hour.
  final double speedKmh;

  final DateTime? timestamp;

  factory IssPosition.fromJson(Map<String, dynamic> json) {
    final Object? rawTimestamp = json['timestamp'];
    final int? unixSeconds = rawTimestamp is num
        ? rawTimestamp.toInt()
        : int.tryParse(readString(rawTimestamp));

    return IssPosition(
      latitude: readDouble(json['latitude']),
      longitude: readDouble(json['longitude']),
      altitude: readDouble(json['altitude']),
      speedKmh: readDouble(json['velocity']),
      timestamp: unixSeconds == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              unixSeconds * 1000,
              isUtc: true,
            ),
    );
  }
}
