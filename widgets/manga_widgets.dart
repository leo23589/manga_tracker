import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../pages/manga_detail_page.dart';
import 'tag_selector.dart';

class ChapterInputWidget extends StatefulWidget {
  final Manga manga;
  final ValueChanged<int> onChapterChanged;

  const ChapterInputWidget({super.key, required this.manga, required this.onChapterChanged});

  @override
  State<ChapterInputWidget> createState() => _ChapterInputWidgetState();
}

class _ChapterInputWidgetState extends State<ChapterInputWidget> {
  late TextEditingController _chapterController;

  @override
  void initState() {
    super.initState();
    _chapterController = TextEditingController(text: widget.manga.currentChapter.toString());
    widget.manga.addListener(_onMangaChapterChanged);
  }

  void _onMangaChapterChanged() {
    if (_chapterController.text != widget.manga.currentChapter.toString()) {
      _chapterController.text = widget.manga.currentChapter.toString();
    }
  }

  @override
  void dispose() {
    widget.manga.removeListener(_onMangaChapterChanged);
    _chapterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.remove, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onPressed: () {
              if (widget.manga.currentChapter > 0) {
                widget.onChapterChanged(widget.manga.currentChapter - 1);
              }
            },
          ),
          SizedBox(
            width: 50,
            child: TextField(
              controller: _chapterController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              onChanged: (String value) {
                int? newChapter = int.tryParse(value);
                if (newChapter != null) {
                  widget.onChapterChanged(newChapter);
                }
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onPressed: () => widget.onChapterChanged(widget.manga.currentChapter + 1),
          ),
        ],
      ),
    );
  }
}

class RatingInputWidget extends StatelessWidget {
  final int currentRating;
  final ValueChanged<int> onRatingChanged;
  final int maxRating;
  final bool enabled;

  const RatingInputWidget({
    super.key,
    required this.currentRating,
    required this.onRatingChanged,
    this.maxRating = 10,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (int index) {
        final int starValue = index + 1;
        return InkWell(
          onTap: enabled ? () => onRatingChanged(starValue) : null,
          child: Icon(
            starValue <= currentRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 28,
          ),
        );
      }),
    );
  }
}

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
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: (currentManga.imagePath != null && File(currentManga.imagePath!).existsSync())
                              ? Image.file(
                                  File(currentManga.imagePath!),
                                  width: 60,
                                  height: 90,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 60,
                                  height: 90,
                                  color: Colors.grey.shade800,
                                  child: Icon(Icons.image_not_supported, color: Colors.grey.shade500),
                                ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(currentManga.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Row(children: List<Widget>.generate(10, (int index) => Icon(index < currentManga.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 16))),
                            Text("Chapter: ${currentManga.currentChapter}", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            DisplayTagList(
                              tags: currentManga.themes,
                              contentTagColor: Colors.red.shade700,
                              themeTagColor: Colors.purple.shade700,
                              genreTagColor: Colors.blue.shade700,
                              textColor: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      ChapterInputWidget(
                        manga: currentManga,
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
