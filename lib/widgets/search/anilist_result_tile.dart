import '../../providers/manga_provider.dart';

import 'package:flutter/material.dart';

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
    final bool isAlreadyInLibrary = collection.mangas.any((m) => m.anilistId == result.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      color: const Color(0xFF161622),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: MangaCoverImage(
          imagePath: result.coverUrl,
          width: 50,
          height: 75,
          borderRadius: 6,
        ),
        title: Text(result.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              result.synopsis.isEmpty ? "No synopsis available." : result.synopsis,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: result.tags.take(3).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withAlpha((255 * 0.3).round()),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(tag, style: const TextStyle(fontSize: 9, color: Colors.cyanAccent)),
                );
              }).toList(),
            ),
          ],
        ),
        trailing: isAlreadyInLibrary
            ? const Icon(Icons.check_circle, color: Colors.green)
            : IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading cover and adding to library...')));
                  final manga = await result.toMangaWithLocalCover();
                  collection.addManga(manga);
                  onStateUpdated();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${manga.title} to library!'), backgroundColor: Colors.green));
                  }
                },
              ),
      ),
    );
  }
}
