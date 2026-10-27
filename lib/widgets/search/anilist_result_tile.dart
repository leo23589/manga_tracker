import 'package:flutter/material.dart';
import '../../models/manga.dart';
import '../../services/anilist_service.dart';
import '../manga_cover_image.dart';

class AniListResultTile extends StatelessWidget {
  final AniListSearchResult result;
  final MangaCollectionData collection;
  final VoidCallback onStateUpdated;

  const AniListResultTile({
    super.key,
    required this.result,
    required this.collection,
    required this.onStateUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAlreadyInLibrary = collection.mangas.any((m) {
      return m.anilistId == result.id ||
          m.title.toLowerCase().trim() == result.title.toLowerCase().trim() ||
          m.altTitles.any((alt) => alt.toLowerCase().trim() == result.title.toLowerCase().trim());
    });

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MangaCoverImage(
              imagePath: result.coverUrl,
              width: 65,
              height: 95,
              borderRadius: 8,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (result.tags.isNotEmpty)
                    Text(
                      result.tags.take(3).join(" • "),
                      style: const TextStyle(fontSize: 11, color: Colors.cyanAccent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Text(
                    result.synopsis.isEmpty ? "No synopsis provided." : result.synopsis,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            isAlreadyInLibrary
                ? const Chip(
                    avatar: Icon(Icons.check, size: 14, color: Colors.greenAccent),
                    label: Text("In Library", style: TextStyle(fontSize: 11, color: Colors.greenAccent)),
                    backgroundColor: Color(0xFF064E3B),
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Add", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading "${result.title}" cover...')),
                      );

                      final Manga newManga = await result.toMangaWithLocalCover();
                      collection.addManga(newManga);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "${result.title}" to library!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        onStateUpdated();
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
