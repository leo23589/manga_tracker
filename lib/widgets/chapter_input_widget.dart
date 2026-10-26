import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/manga.dart';

class ChapterInputWidget extends StatefulWidget {
  final Manga manga;
  final ValueChanged<int> onChapterChanged;
  final bool small;

  const ChapterInputWidget({
    super.key,
    required this.manga,
    required this.onChapterChanged,
    this.small = false,
  });

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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: widget.small ? 32 : 40,
            height: widget.small ? 32 : 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.remove,
                size: widget.small ? 16 : 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                if (widget.manga.currentChapter > 0) {
                  widget.onChapterChanged(widget.manga.currentChapter - 1);
                }
              },
            ),
          ),
          SizedBox(
            width: widget.small ? 30 : 45,
            child: TextField(
              controller: _chapterController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
              style: TextStyle(
                fontSize: widget.small ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              onChanged: (String value) {
                int? newChapter = int.tryParse(value);
                if (newChapter != null) {
                  widget.onChapterChanged(newChapter);
                }
              },
            ),
          ),
          SizedBox(
            width: widget.small ? 32 : 40,
            height: widget.small ? 32 : 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.add,
                size: widget.small ? 16 : 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: () => widget.onChapterChanged(widget.manga.currentChapter + 1),
            ),
          ),
        ],
      ),
    );
  }
}
