import 'package:flutter/material.dart';
import '../../models/manga.dart';
import '../../services/mangadex_service.dart';
import '../manga_cover_image.dart';
import '../tag_selector.dart';

void showMangaDexDetailModal({
  required BuildContext context,
  required MangaDexSearchResult result,
  required MangaCollectionData collection,
  required VoidCallback onStateUpdated,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext modalContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (BuildContext context, ScrollController scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: MangaCoverImage(
                    imagePath: result.coverUrl,
                    width: 150,
                    height: 220,
                    borderRadius: 12.0,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  result.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                DisplayTagList(
                  tags: result.tags,
                  contentTagColor: Colors.red.shade700,
                  themeTagColor: Colors.purple.shade700,
                  genreTagColor: Colors.blue.shade700,
                  textColor: Colors.white,
                ),
                const SizedBox(height: 16),
                Text("Synopsis", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  result.synopsis.isEmpty ? "No synopsis available." : result.synopsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter setModalState) {
                    final bool added = collection.mangas.any(
                      (m) => m.title.toLowerCase() == result.title.toLowerCase(),
                    );
                    return ElevatedButton.icon(
                      onPressed: added
                          ? null
                          : () async {
                              final Manga manga = await result.toMangaWithLocalCover();
                              collection.addManga(manga);
                              setModalState(() {});
                              onStateUpdated();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added "${result.title}" to your library!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                      icon: Icon(added ? Icons.check : Icons.library_add),
                      label: Text(added ? "In Your Library" : "Add to My Library"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: added ? Colors.grey : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
