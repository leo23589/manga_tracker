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

  Color _getStatusColor(MangaStatus status) {
    switch (status) {
      case MangaStatus.reading:
        return const Color(0xFF0284C7);
      case MangaStatus.finished:
        return const Color(0xFF059669);
      case MangaStatus.onHold:
        return const Color(0xFFD97706);
      case MangaStatus.dropped:
        return const Color(0xFFDC2626);
      case MangaStatus.planToRead:
        return const Color(0xFF7C3AED);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
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
                borderRadius: BorderRadius.circular(16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 14.0),
                        child: MangaCoverImage(
                          imagePath: currentManga.imagePath,
                          width: 85,
                          height: 125,
                          borderRadius: 10.0,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              currentManga.title,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            PopupMenuButton<MangaStatus>(
                              tooltip: "Change Status",
                              onSelected: (MangaStatus newStatus) {
                                currentManga.updateStatus(newStatus);
                              },
                              itemBuilder: (BuildContext context) => MangaStatus.values.map((status) {
                                return PopupMenuItem<MangaStatus>(
                                  value: status,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(status.label),
                                    ],
                                  ),
                                );
                              }).toList(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(currentManga.status).withAlpha((255 * 0.25).round()),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _getStatusColor(currentManga.status).withAlpha((255 * 0.6).round()), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(currentManga.status),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      currentManga.status.label,
                                      style: TextStyle(
                                        color: _getStatusColor(currentManga.status),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(Icons.arrow_drop_down, size: 14, color: _getStatusColor(currentManga.status)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: List<Widget>.generate(
                                10,
                                (int index) => Icon(
                                  index < currentManga.rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Chapter: ${currentManga.currentChapter}",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (contentTags.isNotEmpty)
                              DisplayTagList(
                                tags: contentTags,
                                contentTagColor: Colors.red.shade900,
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
