import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

/// Fallback shown when a named route cannot be resolved.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.routeName});

  /// The route that could not be resolved, shown to help debugging.
  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.explore_off, size: 48),
              const SizedBox(height: 16),
              Text(
                'No route is defined for "${routeName ?? 'unknown'}".',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.home,
                  (Route<dynamic> route) => false,
                ),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
