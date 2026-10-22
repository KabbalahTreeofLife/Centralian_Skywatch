import 'package:flutter/material.dart';

/// Favorites tab: saved APOD entries and launches with personal notes.
///
/// The list, note dialog and empty state are implemented in Issue #8.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: const Center(child: Text('No favorites yet.')),
    );
  }
}
