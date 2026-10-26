import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../services/mangadex_service.dart';
import '../widgets/manga_widgets.dart';
import '../widgets/tag_selector.dart';

enum SearchMode { local, mangadex }

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  SearchMode _searchMode = SearchMode.local;

  // Local Search State
  final TextEditingController _localSearchController = TextEditingController();
  List<String> _filterTags = <String>[];
  int _minRating = 0;
  bool _showAdvancedFilters = false;

  // MangaDex Search State
  final TextEditingController _mangadexSearchController = TextEditingController();
  List<MangaDexSearchResult> _mangadexResults = <MangaDexSearchResult>[];
  bool _isLoadingMangaDex = false;
  bool _hasSearchedMangaDex = false;

  @override
  void dispose() {
    _localSearchController.dispose();
    _mangadexSearchController.dispose();
    super.dispose();
  }

  Future<void> _performMangaDexSearch() async {
    final String query = _mangadexSearchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoadingMangaDex = true;
      _hasSearchedMangaDex = true;
    });

    final List<MangaDexSearchResult> results = await MangaDexService.searchManga(query);

    if (mounted) {
      setState(() {
        _mangadexResults = results;
        _isLoadingMangaDex = false;
      });
    }
  }

  void _showMangaDexDetailModal(BuildContext context, MangaDexSearchResult result, MangaCollectionData collection) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: MangaCoverImage(
                      imagePath: result.coverUrl,
                      width: 150,
                      height: 220,
                      borderRadius: 12.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    result.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  DisplayTagList(
                    tags: result.tags,
                    contentTagColor: Colors.red.shade700,
                    themeTagColor: Colors.purple.shade700,
                    genreTagColor: Colors.blue.shade700,
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text("Synopsis", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    result.synopsis.isEmpty ? "No synopsis available." : result.synopsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  StatefulBuilder(
                    builder: (BuildContext context, StateSetter setModalState) {
                      final bool added = collection.mangas.any(
                        (m) => m.title.toLowerCase() == result.title.toLowerCase(),
                      );
                      return ElevatedButton.icon(
                        onPressed: added
                            ? null
                            : () {
                                collection.addManga(result.toManga());
                                setModalState(() {});
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added "${result.title}" to your library!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                        icon: Icon(added ? Icons.check : Icons.library_add),
                        label: Text(added ? "In Your Library" : "Add to My Library"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: added ? Colors.grey : Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMangaDexResultTile(MangaDexSearchResult result, MangaCollectionData collection) {
    final bool isAlreadyInLibrary = collection.mangas.any(
      (m) => m.title.toLowerCase() == result.title.toLowerCase(),
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => _showMangaDexDetailModal(context, result, collection),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MangaCoverImage(
                imagePath: result.coverUrl,
                width: 85,
                height: 125,
                borderRadius: 8.0,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      result.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (result.tags.isNotEmpty) ...[
                      DisplayTagList(
                        tags: result.tags.take(3).toList(),
                        contentTagColor: Colors.red.shade700,
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      result.synopsis.isEmpty ? "No synopsis available." : result.synopsis,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: isAlreadyInLibrary
                          ? null
                          : () {
                              collection.addManga(result.toManga());
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added "${result.title}" to your library!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                      icon: Icon(isAlreadyInLibrary ? Icons.check : Icons.library_add, size: 16),
                      label: Text(isAlreadyInLibrary ? "In Library" : "Add to Library", style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        backgroundColor: isAlreadyInLibrary ? Colors.grey.shade800 : Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MangaCollectionData mangaCollection = context.watch<MangaCollectionData>();

    final List<Manga> filteredLocalMangas = mangaCollection.mangas.where((Manga manga) {
      final bool matchesText = manga.title.toLowerCase().contains(_localSearchController.text.toLowerCase());
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
          const SizedBox(height: 12),
          // Toggle Segmented Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<SearchMode>(
              segments: const <ButtonSegment<SearchMode>>[
                ButtonSegment<SearchMode>(
                  value: SearchMode.local,
                  label: Text("My Library"),
                  icon: Icon(Icons.library_books),
                ),
                ButtonSegment<SearchMode>(
                  value: SearchMode.mangadex,
                  label: Text("MangaDex Online"),
                  icon: Icon(Icons.public),
                ),
              ],
              selected: <SearchMode>{_searchMode},
              onSelectionChanged: (Set<SearchMode> newSelection) {
                setState(() {
                  _searchMode = newSelection.first;
                });
              },
            ),
          ),
          const SizedBox(height: 12),

          // Search Mode Specific UI
          if (_searchMode == SearchMode.local) ...[
            Container(
              color: Theme.of(context).colorScheme.surface,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: _localSearchController,
                        decoration: InputDecoration(
                          hintText: "Search in my library...",
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
                            Text(
                              "Advanced Filters (${_filterTags.length + (_minRating > 0 ? 1 : 0)} active)",
                              style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                            ),
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
              child: filteredLocalMangas.isEmpty
                  ? const Center(child: Text("No mangas found in your library."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: filteredLocalMangas.length,
                      itemBuilder: (BuildContext context, int index) {
                        return MangaListTile(manga: filteredLocalMangas[index]);
                      },
                    ),
            ),
          ] else ...[
            // MangaDex Search Mode UI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _mangadexSearchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performMangaDexSearch(),
                decoration: InputDecoration(
                  hintText: "Search MangaDex online...",
                  prefixIcon: const Icon(Icons.public_search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _performMangaDexSearch,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoadingMangaDex
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text("Searching MangaDex..."),
                        ],
                      ),
                    )
                  : !_hasSearchedMangaDex
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.travel_explore, size: 64, color: Colors.grey.shade600),
                              const SizedBox(height: 12),
                              const Text("Search for titles on MangaDex to import them!"),
                            ],
                          ),
                        )
                      : _mangadexResults.isEmpty
                          ? const Center(child: Text("No results found on MangaDex."))
                          : ListView.builder(
                              padding: const EdgeInsets.all(10),
                              itemCount: _mangadexResults.length,
                              itemBuilder: (BuildContext context, int index) {
                                return _buildMangaDexResultTile(_mangadexResults[index], mangaCollection);
                              },
                            ),
            ),
          ],
        ],
      ),
    );
  }
}
