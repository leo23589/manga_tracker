import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../services/mangadex_service.dart';
import '../widgets/dialogs/mangadex_autofill_dialog.dart';
import '../widgets/manga_widgets.dart';

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

  void _showQuickCoverOptionsSheet(Manga manga) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Change Cover Image", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.indigoAccent),
                title: const Text("Pick from Gallery"),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _updateImage();
                  if (_temporaryImagePath != null) {
                    manga.updateImage(_temporaryImagePath);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.travel_explore, color: Colors.indigoAccent),
                title: const Text("Search & Set Cover from MangaDex"),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showMangaDexAutofillDialog(
                    parentContext: context,
                    initialQuery: manga.title,
                    onSelect: (result) async {
                      final localPath = await MangaDexService.downloadCoverImageLocally(result.coverUrl);
                      if (localPath != null) {
                        manga.updateImage(localPath);
                        setState(() => _temporaryImagePath = localPath);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cover image updated!'), backgroundColor: Colors.green),
                          );
                        }
                      }
                    },
                  );
                },
              ),
              if (manga.imagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text("Remove Cover", style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    manga.updateImage(null);
                    setState(() => _temporaryImagePath = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _linkWithMangaDex(Manga manga) {
    showMangaDexAutofillDialog(
      parentContext: context,
      initialQuery: manga.title,
      onSelect: (result) async {
        final localPath = await MangaDexService.downloadCoverImageLocally(result.coverUrl);
        manga.updateTitle(result.title);
        manga.updateSynopsis(result.synopsis);
        manga.updateThemes(result.tags);
        if (localPath != null) {
          manga.updateImage(localPath);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Linked "${result.title}" with MangaDex!'), backgroundColor: Colors.green),
          );
        }
      },
    );
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
                } else if (result == 'link_mangadex') {
                  _linkWithMangaDex(widget.manga);
                } else if (result == 'delete') {
                  _showDeleteConfirmationDialog(widget.manga);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit_details',
                  child: Row(children: <Widget>[Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit Details')]),
                ),
                const PopupMenuItem<String>(
                  value: 'link_mangadex',
                  child: Row(children: <Widget>[Icon(Icons.auto_awesome, color: Colors.indigoAccent, size: 20), SizedBox(width: 8), Text('Link with MangaDex')]),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(children: <Widget>[Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Delete Manga', style: TextStyle(color: Colors.red))]),
                ),
              ],
              icon: const Icon(Icons.more_vert),
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
                    onTap: _isEditing ? _updateImage : () => _showQuickCoverOptionsSheet(manga),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        MangaCoverImage(
                          imagePath: displayPath,
                          width: 200,
                          height: 300,
                          borderRadius: 12.0,
                        ),
                        Container(
                          width: 200,
                          height: 300,
                          decoration: BoxDecoration(
                            color: _isEditing ? Colors.black38 : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isEditing ? Icons.camera_alt : Icons.edit,
                            size: _isEditing ? 50 : 28,
                            color: Colors.white.withAlpha(_isEditing ? 200 : 80),
                          ),
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
                    : Center(
                        child: Text(
                          manga.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text("Reading Status:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E28),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.indigo.withAlpha((255 * 0.5).round())),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<MangaStatus>(
                          value: manga.status,
                          dropdownColor: const Color(0xFF1E1E28),
                          onChanged: (MangaStatus? newStatus) {
                            if (newStatus != null) {
                              manga.updateStatus(newStatus);
                            }
                          },
                          items: MangaStatus.values.map((MangaStatus status) {
                            return DropdownMenuItem<MangaStatus>(
                              value: status,
                              child: Text(
                                status.label,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text("Current Chapter:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    ChapterInputWidget(manga: manga, onChapterChanged: (int val) => manga.updateChapter(val)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text("Rating:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    RatingInputWidget(currentRating: manga.rating, onRatingChanged: (int val) => manga.updateRating(val), enabled: _isEditing),
                  ],
                ),
                const SizedBox(height: 24),
                Text("Synopsis", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _isEditing
                    ? TextField(controller: _synopsisEditController, maxLines: null, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Write synopsis here..."))
                    : Text(manga.synopsis.isEmpty ? "No synopsis provided." : manga.synopsis, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                Text("Themes", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _isEditing
                    ? TagSelector(selectedTags: _temporarySelectedThemes, onSelectionChanged: (List<String> newTags) => setState(() => _temporarySelectedThemes = newTags), enabled: true)
                    : DisplayTagList(
                        tags: manga.themes,
                        contentTagColor: Colors.red.shade900,
                        themeTagColor: Colors.purple.shade900,
                        genreTagColor: Colors.blue.shade900,
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
