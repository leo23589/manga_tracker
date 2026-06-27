import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../widgets/manga_widgets.dart';
import '../widgets/tag_selector.dart';

class MangaDetailPage extends StatefulWidget {
  final Manga manga;
  const MangaDetailPage({super.key, required this.manga});

  @override
  State<MangaDetailPage> createState() => _MangaDetailPageState();
}

class _MangaDetailPageState extends State<MangaDetailPage> {
  late TextEditingController _synopsisEditController;
  late TextEditingController _titleEditController;
  late List<String> _temporarySelectedThemes;
  String? _temporaryImagePath;
  bool _isEditing = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _synopsisEditController = TextEditingController(text: widget.manga.synopsis);
    _titleEditController = TextEditingController(text: widget.manga.title);
    _temporarySelectedThemes = List<String>.from(widget.manga.themes);
    _temporaryImagePath = widget.manga.imagePath;
  }

  @override
  void dispose() {
    _synopsisEditController.dispose();
    _titleEditController.dispose();
    super.dispose();
  }

  Future<void> _updateImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String fileName = path.basename(image.path);
    final String localPath = path.join(appDir.path, fileName);

    await File(image.path).copy(localPath);
    setState(() {
      _temporaryImagePath = localPath;
    });
  }

  void _showDeleteConfirmationDialog(Manga manga) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm deletion'),
          content: Text('Are you sure you want to delete "${manga.title}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<MangaCollectionData>(context, listen: false).deleteManga(manga);
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _enterEditMode() {
    setState(() {
      _isEditing = true;
      _synopsisEditController.text = widget.manga.synopsis;
      _titleEditController.text = widget.manga.title;
      _temporarySelectedThemes = List<String>.from(widget.manga.themes);
      _temporaryImagePath = widget.manga.imagePath;
    });
  }

  void _saveChanges() {
    if (_titleEditController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title cannot be empty.')));
      return;
    }
    widget.manga.updateTitle(_titleEditController.text.trim());
    widget.manga.updateSynopsis(_synopsisEditController.text);
    widget.manga.updateThemes(_temporarySelectedThemes);
    widget.manga.updateImage(_temporaryImagePath);
    setState(() {
      _isEditing = false;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _synopsisEditController.text = widget.manga.synopsis;
      _titleEditController.text = widget.manga.title;
      _temporarySelectedThemes = List<String>.from(widget.manga.themes);
      _temporaryImagePath = widget.manga.imagePath;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Manga" : widget.manga.title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        leading: _isEditing ? IconButton(icon: const Icon(Icons.cancel), onPressed: _cancelEdit) : null,
        actions: <Widget>[
          if (_isEditing)
            IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges)
          else
            PopupMenuButton<String>(
              onSelected: (String result) {
                if (result == 'edit_details') {
                  _enterEditMode();
                } else if (result == 'delete') {
                  _showDeleteConfirmationDialog(widget.manga);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'edit_details', child: Row(children: <Widget>[Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit Details')])),
                const PopupMenuItem<String>(value: 'delete', child: Row(children: <Widget>[Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Delete Manga', style: TextStyle(color: Colors.red))])),
              ],
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: Consumer<Manga>(
        builder: (BuildContext context, Manga manga, Widget? child) {
          final String? displayPath = _isEditing ? _temporaryImagePath : manga.imagePath;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: GestureDetector(
                    onTap: _isEditing ? _updateImage : null,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: (displayPath != null && File(displayPath).existsSync())
                              ? Image.file(
                                  File(displayPath),
                                  width: 200,
                                  height: 300,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 200,
                                  height: 300,
                                  color: Colors.grey.shade800,
                                  child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey.shade500),
                                ),
                        ),
                        if (_isEditing)
                          Container(
                            width: 200,
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.camera_alt, size: 50, color: Colors.white70),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _isEditing
                    ? TextField(
                        controller: _titleEditController,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(hintText: "Manga Title", border: InputBorder.none))
                    : Text(manga.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                  const Text("Current Chapter:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ChapterInputWidget(manga: manga, onChapterChanged: (int val) => manga.updateChapter(val)),
                ]),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                  const Text("Rating:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  RatingInputWidget(currentRating: manga.rating, onRatingChanged: (int val) => manga.updateRating(val), enabled: _isEditing),
                ]),
                const SizedBox(height: 24),
                Text("Synopsis", style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                _isEditing
                    ? TextField(controller: _synopsisEditController, maxLines: null, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Write synopsis here..."))
                    : Text(manga.synopsis.isEmpty ? "No synopsis provided." : manga.synopsis, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                Text("Themes", style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                _isEditing
                    ? TagSelector(selectedTags: _temporarySelectedThemes, onSelectionChanged: (List<String> newTags) => setState(() => _temporarySelectedThemes = newTags), enabled: true)
                    : DisplayTagList(
                        tags: manga.themes,
                        contentTagColor: Colors.red.shade700,
                        themeTagColor: Colors.purple.shade700,
                        genreTagColor: Colors.blue.shade700,
                        textColor: Colors.white,
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
