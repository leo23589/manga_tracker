import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../services/mangadex_service.dart';
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

  void _showMangaDexAutofillDialog(
    BuildContext parentContext,
    String initialQuery,
    Function(MangaDexSearchResult) onSelect,
  ) {
    final TextEditingController searchController = TextEditingController(text: initialQuery);
    List<MangaDexSearchResult> results = <MangaDexSearchResult>[];
    bool isLoading = false;
    bool hasSearched = false;

    showDialog<void>(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            Future<void> performSearch() async {
              final String query = searchController.text.trim();
              if (query.isEmpty) return;

              setState(() {
                isLoading = true;
                hasSearched = true;
              });

              final List<MangaDexSearchResult> res = await MangaDexService.searchManga(query);

              if (context.mounted) {
                setState(() {
                  results = res;
                  isLoading = false;
                });
              }
            }

            return AlertDialog(
              title: const Text("Autofill from MangaDex"),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Manga title...",
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: performSearch,
                        ),
                      ),
                      onSubmitted: (_) => performSearch(),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : !hasSearched
                              ? const Center(child: Text("Type a title and press search."))
                              : results.isEmpty
                                  ? const Center(child: Text("No results found."))
                                  : ListView.builder(
                                      itemCount: results.length,
                                      itemBuilder: (context, index) {
                                        final item = results[index];
                                        return ListTile(
                                          leading: MangaCoverImage(
                                            imagePath: item.coverUrl,
                                            width: 40,
                                            height: 60,
                                            borderRadius: 4,
                                          ),
                                          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                          subtitle: Text(
                                            item.tags.join(", "),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                          onTap: () {
                                            onSelect(item);
                                            Navigator.of(dialogContext).pop();
                                          },
                                        );
                                      },
                                    ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
    );
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
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("New Manga", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  IconButton(
                    icon: const Icon(Icons.auto_awesome, color: Colors.indigoAccent),
                    tooltip: "Autofill from MangaDex",
                    onPressed: () {
                      _showMangaDexAutofillDialog(
                        context,
                        titleController.text,
                        (MangaDexSearchResult result) {
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
                          final String? savedPath = await _pickAndSaveImage();
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
                          _showMangaDexAutofillDialog(
                            context,
                            titleController.text,
                            (MangaDexSearchResult result) {
                              setState(() {
                                titleController.text = result.title;
                                synopsisController.text = result.synopsis;
                                tempImagePath = result.coverUrl;
                                currentSelectedTags = result.tags;
                              });
                            },
                          );
                        },
                        icon: const Icon(Icons.public_search, size: 18),
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
                child: Row(children: [Icon(Icons.more_time, size: 20), SizedBox(width: 8), Text('Recently Added')]),
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
