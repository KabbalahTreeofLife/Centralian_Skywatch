import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/favorite_item.dart';
import '../providers/favorites_provider.dart';

/// Favorites tab: saved APOD entries and launches with personal notes.
///
/// This is the read/update/delete half of the app's CRUD entity; the create
/// half lives on the Home and Launches screens.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FavoritesProvider provider = context.watch<FavoritesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: _body(provider),
    );
  }

  Widget _body(FavoritesProvider provider) {
    // Favorites are read from local storage at startup, so this is only
    // visible for the first frame or two. A spinner would just flash.
    if (!provider.isLoaded) return const SizedBox.shrink();
    if (provider.isEmpty) return const _EmptyState();

    return ListView.separated(
      itemCount: provider.count,
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) =>
          _FavoriteTile(item: provider.items[index]),
    );
  }
}

/// Shown when nothing has been saved yet.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.favorite_outline,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('No favorites yet.', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Save a picture from Home or a launch from Launches '
              'to see it here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One saved favorite, with its note and the edit/delete menu.
class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.item});

  final FavoriteItem item;

  @override
  Widget build(BuildContext context) {
    final FavoritesProvider provider = context.read<FavoritesProvider>();

    return ListTile(
      leading: Icon(
        item.type == FavoriteType.apod
            ? Icons.image_outlined
            : Icons.rocket_launch_outlined,
      ),
      title: Text(item.title),
      subtitle: Text(item.note.isEmpty ? 'No note' : item.note),
      onTap: () => _editNote(context, provider),
      trailing: PopupMenuButton<_FavoriteAction>(
        onSelected: (_FavoriteAction action) {
          if (action == _FavoriteAction.editNote) {
            _editNote(context, provider);
          } else {
            _confirmDelete(context, provider);
          }
        },
        itemBuilder: (BuildContext context) =>
            const <PopupMenuEntry<_FavoriteAction>>[
              PopupMenuItem<_FavoriteAction>(
                value: _FavoriteAction.editNote,
                child: Text('Edit note'),
              ),
              PopupMenuItem<_FavoriteAction>(
                value: _FavoriteAction.delete,
                child: Text('Delete'),
              ),
            ],
      ),
    );
  }

  Future<void> _editNote(
    BuildContext context,
    FavoritesProvider provider,
  ) async {
    final String? note = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _NoteDialog(initialNote: item.note),
    );
    if (note == null) return;

    await provider.updateNote(item.type, item.id, note);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FavoritesProvider provider,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Remove favorite?'),
        content: Text('"${item.title}" will be removed from your favorites.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await provider.remove(item.type, item.id);
  }
}

enum _FavoriteAction { editNote, delete }

/// Dialog for writing or editing a favorite's note.
class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.initialNote});

  final String initialNote;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  static const int maxLength = 200;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialNote,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Note'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          minLines: 1,
          maxLines: 3,
          maxLength: maxLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Your note',
            hintText: 'Why did you save this?',
          ),
          validator: (String? value) {
            final String note = (value ?? '').trim();
            if (note.isEmpty) return 'Note cannot be empty';
            if (note.length > maxLength) {
              return 'Keep it under $maxLength characters';
            }
            return null;
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
