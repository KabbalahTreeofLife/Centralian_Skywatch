import 'package:flutter/material.dart';

/// Detail screen pushed on top of the shell.
///
/// It renders the launch passed as a route argument. Until the Launch model
/// exists (Issue #3) the argument is a placeholder String; Issue #6 will type
/// it as Launch and render the full details.
class LaunchDetailScreen extends StatelessWidget {
  const LaunchDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Object? argument = ModalRoute.of(context)?.settings.arguments;
    final String title = argument is String ? argument : 'Launch Detail';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            argument == null
                ? 'No launch was passed to this screen.'
                : 'Selected launch:\n\n$title',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
