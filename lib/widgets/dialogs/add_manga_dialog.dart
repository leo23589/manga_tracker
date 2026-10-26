import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../models/manga.dart';
import '../../services/mangadex_service.dart';
import '../manga_cover_image.dart';
import '../tag_selector.dart';
import 'mangadex_autofill_dialog.dart';

void showAddMangaDialog({
  required BuildContext context,
  required MangaCollectionData mangaCollection,
}) {
  final ImagePicker picker = ImagePicker();

  Future<String?> pickAndSaveImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String fileName = path.basename(image.path);
    final String localPath = path.join(appDir.path, fileName);

    await File(image.path).copy(localPath);
    return localPath;
  }

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
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("New Manga", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                IconButton(
                  icon: const Icon(Icons.auto_awesome, color: Colors.indigoAccent),
                  tooltip: "Autofill from MangaDex",
                  onPressed: () {
                    showMangaDexAutofillDialog(
                      parentContext: context,
                      initialQuery: titleController.text,
                      onSelect: (MangaDexSearchResult result) {
                        setState(() {
                          titleController.text = result.title;
                          synopsisController.text = result.synopsis;
                          tempImagePath = result.coverUrl;
                          currentSelectedTags = result.tags;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () async {
                        final String? savedPath = await pickAndSaveImage();
                        if (savedPath != null) {
                          setState(() => tempImagePath = savedPath);
                        }
                      },
                      child: tempImagePath != null
                          ? MangaCoverImage(
                              imagePath: tempImagePath,
                              width: 100,
                              height: 150,
                              borderRadius: 8.0,
                            )
                          : Container(
                              height: 150,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_a_photo, size: 40, color: Colors.white54),
                            ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        showMangaDexAutofillDialog(
                          parentContext: context,
                          initialQuery: titleController.text,
                          onSelect: (MangaDexSearchResult result) {
                            setState(() {
                              titleController.text = result.title;
                              synopsisController.text = result.synopsis;
                              tempImagePath = result.coverUrl;
                              currentSelectedTags = result.tags;
                            });
                          },
                        );
                      },
                      icon: const Icon(Icons.travel_explore, size: 18),
                      label: const Text("Autofill from MangaDex"),
                    ),
                    const SizedBox(height: 12),
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
