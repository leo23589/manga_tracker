import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../widgets/dialogs/add_manga_dialog.dart';
import '../widgets/manga_widgets.dart';

class MangaListPage extends StatelessWidget {
  const MangaListPage({super.key});

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
        onPressed: () => showAddMangaDialog(
          context: context,
          mangaCollection: mangaCollection,
        ),
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
