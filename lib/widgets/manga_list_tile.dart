import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../pages/manga_detail_page.dart';
import '../core/constants.dart';
import 'manga_cover_image.dart';
import 'chapter_input_widget.dart';
import 'tag_selector.dart';

class MangaListTile extends StatelessWidget {
  final Manga manga;

  const MangaListTile({super.key, required this.manga});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ChangeNotifierProvider<Manga>.value(
        value: manga,
        builder: (BuildContext context, Widget? child) {
          return Consumer<Manga>(
            builder: (BuildContext context, Manga currentManga, Widget? child) {
              final contentTags = currentManga.themes
                  .where((tag) => AppConstants.content.contains(tag))
                  .toList();

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => ChangeNotifierProvider<Manga>.value(
                        value: currentManga,
                        child: MangaDetailPage(manga: currentManga),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: MangaCoverImage(
                          imagePath: currentManga.imagePath,
                          width: 85,
                          height: 125,
                          borderRadius: 8.0,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              currentManga.title,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List<Widget>.generate(
                                10,
                                (int index) => Icon(
                                  index < currentManga.rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Chapter: ${currentManga.currentChapter}",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (contentTags.isNotEmpty)
                              DisplayTagList(
                                tags: contentTags,
                                contentTagColor: Colors.red.shade700,
                                textColor: Colors.white,
                              ),
                          ],
                        ),
                      ),
                      ChapterInputWidget(
                        manga: currentManga,
                        small: true,
                        onChapterChanged: (int val) => currentManga.updateChapter(val),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
