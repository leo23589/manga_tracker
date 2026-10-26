import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../widgets/dialogs/add_manga_dialog.dart';
import '../widgets/manga_widgets.dart';

class MangaListPage extends StatefulWidget {
  const MangaListPage({super.key});

  @override
  State<MangaListPage> createState() => _MangaListPageState();
}

class _MangaListPageState extends State<MangaListPage> {
  final TextEditingController _searchController = TextEditingController();
  MangaStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MangaCollectionData mangaCollection = context.watch<MangaCollectionData>();

    final List<Manga> filteredList = mangaCollection.mangas.where((manga) {
      final matchesSearch = manga.title.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesStatus = _statusFilter == null || manga.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Library 📚"),
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
      body: Column(
        children: [
          // Home Page Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Quick search library...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFF1E1E28),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text("All"),
                  selected: _statusFilter == null,
                  onSelected: (_) => setState(() => _statusFilter = null),
                ),
                const SizedBox(width: 8),
                ...MangaStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(status.label),
                      selected: _statusFilter == status,
                      onSelected: (selected) {
                        setState(() {
                          _statusFilter = selected ? status : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isNotEmpty || _statusFilter != null
                          ? "No mangas match your search."
                          : "No mangas found in your library.",
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredList.length,
                    padding: const EdgeInsets.all(10),
                    itemBuilder: (BuildContext context, int index) {
                      return MangaListTile(
                        key: ValueKey(filteredList[index].title + filteredList[index].createdAt.toString()),
                        manga: filteredList[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
