import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/apod.dart';
import '../models/favorite_item.dart';
import '../models/launch.dart';
import '../providers/apod_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/launch_provider.dart';
import '../screens/home_screen.dart';
import '../screens/launch_detail_screen.dart';
import '../widgets/favorite_feedback.dart';
import '../widgets/load_state_views.dart';

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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _body(provider),
      ),
    );
  }

  Widget _body(FavoritesProvider provider) {
    // Favorites are read from local storage at startup, so this is only
    // visible for the first frame or two. A spinner would just flash.
    if (!provider.isLoaded) return const SizedBox.shrink();
    if (provider.isEmpty) {
      return const EmptyStateView(
        icon: Icons.favorite_outline,
        title: 'No favorites yet.',
        message:
            'Save a picture from Home or a launch from Launches '
            'to see it here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: provider.count,
      itemBuilder: (BuildContext context, int index) =>
          _FavoriteTile(item: provider.items[index]),
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isApod = item.type == FavoriteType.apod;
    final Object? rawImage = item.data?['hdurl'] ?? item.data?['image'];
    final String? savedImageUrl = rawImage is String && rawImage.isNotEmpty
        ? rawImage
        : null;
    final String? imageUrl =
        savedImageUrl ??
        (isApod
            ? _currentApod(context, item.id)?.imageUrl
            : _currentLaunch(context, item.id)?.imageUrl);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _FavoritePhoto(
                imageUrl: imageUrl,
                fallbackIcon: isApod
                    ? Icons.image_outlined
                    : Icons.rocket_launch_outlined,
                label: item.title,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.note.isEmpty ? 'No note' : item.note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontStyle: item.note.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_FavoriteAction>(
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
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    final Map<String, dynamic>? data = item.data;
    if (item.type == FavoriteType.apod) {
      final Apod? current = data == null
          ? _currentApod(context, item.id)
          : Apod.fromJson(data);
      if (current == null) {
        _showLegacyDetailsMessage(context);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => ApodDetailScreen(apod: current),
        ),
      );
      return;
    }

    final Launch? launch = data == null
        ? _currentLaunch(context, item.id)
        : Launch.fromJson(data);
    if (launch == null) {
      _showLegacyDetailsMessage(context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(arguments: launch),
        builder: (BuildContext context) => const LaunchDetailScreen(),
      ),
    );
  }

  Apod? _currentApod(BuildContext context, String id) {
    final ApodProvider? provider = Provider.of<ApodProvider?>(
      context,
      listen: false,
    );
    final Apod? current = provider?.data;
    return current?.date == id ? current : null;
  }

  Launch? _currentLaunch(BuildContext context, String id) {
    final LaunchProvider? provider = Provider.of<LaunchProvider?>(
      context,
      listen: false,
    );
    for (final Launch launch in provider?.data ?? const <Launch>[]) {
      if (launch.id == id) return launch;
    }
    return null;
  }

  void _showLegacyDetailsMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Details are unavailable for this older favorite. '
            'Save it again from its screen to keep a bookmark.',
          ),
        ),
      );
  }

  Future<void> _editNote(
    BuildContext context,
    FavoritesProvider provider,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String? note = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _NoteDialog(initialNote: item.note),
    );
    if (note == null) return;

    final bool saved = await provider.updateNote(item.type, item.id, note);
    // False also means the favorite was deleted while the dialog was open,
    // which is not a storage failure, so only a favorite that is still there
    // counts as one.
    if (!saved && provider.contains(item.type, item.id)) {
      showFavoriteSaveError(messenger);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FavoritesProvider provider,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
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

    final bool removed = await provider.remove(item.type, item.id);
    // Still present after a false result means storage rejected the removal.
    if (!removed && provider.contains(item.type, item.id)) {
      showFavoriteSaveError(messenger);
    }
  }
}

class _FavoritePhoto extends StatelessWidget {
  const _FavoritePhoto({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.label,
  });

  final String? imageUrl;
  final IconData fallbackIcon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? url = imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 64,
        height: 64,
        child: url == null
            ? _placeholder(scheme)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                imageBuilder:
                    (BuildContext context, ImageProvider<Object> image) =>
                        Semantics(
                          label: label,
                          image: true,
                          child: Image(image: image, fit: BoxFit.cover),
                        ),
                placeholder: (BuildContext context, String url) =>
                    _placeholder(scheme),
                errorWidget: (BuildContext context, String url, Object _) =>
                    _placeholder(scheme),
              ),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.primaryContainer,
      child: Icon(fallbackIcon, color: scheme.onPrimaryContainer),
    );
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
