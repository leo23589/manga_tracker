import 'package:flutter/material.dart';
import '../../models/manga.dart';
import '../../services/mangadex_service.dart';
import '../manga_cover_image.dart';
import '../tag_selector.dart';
import 'mangadex_detail_modal.dart';

class MangaDexResultTile extends StatelessWidget {
  final MangaDexSearchResult result;
  final MangaCollectionData collection;
  final VoidCallback onStateUpdated;

  const MangaDexResultTile({
    super.key,
    required this.result,
    required this.collection,
    required this.onStateUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAlreadyInLibrary = collection.mangas.any(
      (m) => m.title.toLowerCase() == result.title.toLowerCase(),
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => showMangaDexDetailModal(
          context: context,
          result: result,
          collection: collection,
          onStateUpdated: onStateUpdated,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MangaCoverImage(
                imagePath: result.coverUrl,
                width: 85,
                height: 125,
                borderRadius: 8.0,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      result.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (result.tags.isNotEmpty) ...[
                      DisplayTagList(
                        tags: result.tags.take(3).toList(),
                        contentTagColor: Colors.red.shade700,
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      result.synopsis.isEmpty ? "No synopsis available." : result.synopsis,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: isAlreadyInLibrary
                          ? null
                          : () async {
                              final Manga manga = await result.toMangaWithLocalCover();
                              collection.addManga(manga);
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
                      icon: Icon(isAlreadyInLibrary ? Icons.check : Icons.library_add, size: 16),
                      label: Text(
                        isAlreadyInLibrary ? "In Library" : "Add to Library",
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        backgroundColor: isAlreadyInLibrary ? Colors.grey.shade800 : Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
