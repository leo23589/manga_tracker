import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../widgets/manga_widgets.dart';
import '../widgets/tag_selector.dart';

class MangaListPage extends StatefulWidget {
  const MangaListPage({super.key});

  @override
  State<MangaListPage> createState() => _MangaListPageState();
}

class _MangaListPageState extends State<MangaListPage> {
  final ImagePicker _picker = ImagePicker();

  Future<String?> _pickAndSaveImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String fileName = path.basename(image.path);
    final String localPath = path.join(appDir.path, fileName);

    await File(image.path).copy(localPath);
    return localPath;
  }

  void _showAddDialog(MangaCollectionData mangaCollection) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController synopsisController = TextEditingController();
    List<String> currentSelectedTags = <String>[];
    String? tempImagePath;

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text("New Manga", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      GestureDetector(
                        onTap: () async {
                          final String? savedPath = await _pickAndSaveImage();
                          if (savedPath != null) {
                            setState(() => tempImagePath = savedPath);
                          }
                        },
                        child: Container(
                          height: 150,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(8),
                            image: tempImagePath != null
                                ? DecorationImage(image: FileImage(File(tempImagePath!)), fit: BoxFit.cover)
                                : null,
                          ),
                          child: tempImagePath == null
                              ? const Icon(Icons.add_a_photo, size: 40, color: Colors.white54)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
                      TextField(controller: synopsisController, maxLines: 3, decoration: const InputDecoration(labelText: "Synopsis")),
                      const SizedBox(height: 20),
                      TagSelector(
                        selectedTags: currentSelectedTags,
                        onSelectionChanged: (List<String> newTags) {
                          setState(() {
                            currentSelectedTags = newTags;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      mangaCollection.addManga(Manga(
                          title: titleController.text,
                          imagePath: tempImagePath,
                          synopsis: synopsisController.text,
                          themes: currentSelectedTags));
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final MangaCollectionData mangaCollection = context.watch<MangaCollectionData>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Mangas 📚"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          PopupMenuButton<MangaSortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (MangaSortOption option) {
              mangaCollection.sortOption = option;
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<MangaSortOption>>[
              const PopupMenuItem<MangaSortOption>(
                value: MangaSortOption.lastAdded,
                child: Row(children: [Icon(Icons.add_time, size: 20), SizedBox(width: 8), Text('Recently Added')]),
              ),
              const PopupMenuItem<MangaSortOption>(
                value: MangaSortOption.lastUpdated,
                child: Row(children: [Icon(Icons.update, size: 20), SizedBox(width: 8), Text('Recently Updated')]),
              ),
              const PopupMenuItem<MangaSortOption>(
                value: MangaSortOption.rating,
                child: Row(children: [Icon(Icons.star, size: 20), SizedBox(width: 8), Text('Highest Rated')]),
              ),
              const PopupMenuItem<MangaSortOption>(
                value: MangaSortOption.title,
                child: Row(children: [Icon(Icons.sort_by_alpha, size: 20), SizedBox(width: 8), Text('Alphabetical')]),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(mangaCollection),
        child: const Icon(Icons.add),
      ),
      body: mangaCollection.mangas.isEmpty
          ? Center(child: Text("No mangas found.", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)))
          : ListView.builder(
              itemCount: mangaCollection.mangas.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (BuildContext context, int index) {
                return MangaListTile(
                  key: ValueKey(mangaCollection.mangas[index].title + mangaCollection.mangas[index].createdAt.toString()),
                  manga: mangaCollection.mangas[index],
                );
              },
            ),
    );
  }
}
