import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../widgets/manga_widgets.dart';
import '../widgets/tag_selector.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filterTags = <String>[];
  int _minRating = 0;
  bool _showAdvancedFilters = false;

  @override
  Widget build(BuildContext context) {
    final MangaCollectionData mangaCollection = context.watch<MangaCollectionData>();

    final List<Manga> filteredMangas = mangaCollection.mangas.where((Manga manga) {
      final bool matchesText = manga.title.toLowerCase().contains(_searchController.text.toLowerCase());
      final bool matchesTags = _filterTags.isEmpty || _filterTags.every((String tag) => manga.themes.contains(tag));
      final bool matchesRating = manga.rating >= _minRating;

      return matchesText && matchesTags && matchesRating;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Search"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: <Widget>[
          Container(
            color: Theme.of(context).colorScheme.surface,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search title...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
                      ),
                      onChanged: (String val) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => setState(() => _showAdvancedFilters = !_showAdvancedFilters),
                      child: Row(
                        children: <Widget>[
                          Icon(_showAdvancedFilters ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Text("Advanced Filters (${_filterTags.length + (_minRating > 0 ? 1 : 0)} active)", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (_showAdvancedFilters)
                      Column(
                        children: <Widget>[
                          const SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text("Minimum Rating:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 8),
                              RatingInputWidget(
                                currentRating: _minRating,
                                onRatingChanged: (int newRating) {
                                  setState(() {
                                    _minRating = newRating;
                                  });
                                },
                                maxRating: 10,
                                enabled: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 200, 
                            margin: const EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade800),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(8),
                              child: TagSelector(
                                selectedTags: _filterTags,
                                onSelectionChanged: (List<String> tags) => setState(() => _filterTags = tags),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filteredMangas.isEmpty
                ? const Center(child: Text("No results found."))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: filteredMangas.length,
                    itemBuilder: (BuildContext context, int index) {
                      return MangaListTile(manga: filteredMangas[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
