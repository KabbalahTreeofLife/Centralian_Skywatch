import 'package:flutter/material.dart';

import '../models/iss_position.dart';

/// The station's numbers, as a grid of labelled readouts.
///
/// Kept separate from the map so the values stay readable when the map is
/// unavailable, and so they can be tested without rendering tiles.
class IssReadouts extends StatelessWidget {
  const IssReadouts({super.key, required this.position});

  final IssPosition position;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _Readout(
              icon: Icons.explore_outlined,
              label: 'Latitude',
              value: formatCoordinate(position.latitude, 'N', 'S'),
            ),
          ),
          Expanded(
            child: _Readout(
              icon: Icons.explore_outlined,
              label: 'Longitude',
              value: formatCoordinate(position.longitude, 'E', 'W'),
            ),
          ),
          Expanded(
            child: _Readout(
              icon: Icons.height_outlined,
              label: 'Altitude',
              value: '${position.altitude.toStringAsFixed(1)} km',
            ),
          ),
          Expanded(
            child: _Readout(
              icon: Icons.speed_outlined,
              label: 'Speed',
              value: '${position.speedKmh.toStringAsFixed(0)} km/h',
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats [value] as a signed coordinate, e.g. `51.6° N`.
///
/// The API reports south and west as negative numbers, so the sign is turned
/// into a hemisphere letter rather than shown as a minus.
String formatCoordinate(double value, String positive, String negative) {
  final String hemisphere = value < 0 ? negative : positive;
  return '${value.abs().toStringAsFixed(2)}° $hemisphere';
}

/// One labelled value.
class _Readout extends StatelessWidget {
  const _Readout({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
