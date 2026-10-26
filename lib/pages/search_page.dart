import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../services/mangadex_service.dart';
import '../widgets/manga_widgets.dart';
import '../widgets/search/mangadex_result_tile.dart';

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
  MangaStatus? _selectedStatusFilter;

  // MangaDex Search State
  final TextEditingController _mangadexSearchController = TextEditingController();
  List<MangaDexSearchResult> _mangadexResults = <MangaDexSearchResult>[];
  bool _isLoadingMangaDex = false;
  bool _hasSearchedMangaDex = false;
  bool _isOfflineError = false;

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
      _isOfflineError = false;
    });

    try {
      final List<MangaDexSearchResult> results = await MangaDexService.searchManga(query);

      if (mounted) {
        setState(() {
          _mangadexResults = results;
          _isLoadingMangaDex = false;
          _isOfflineError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mangadexResults = <MangaDexSearchResult>[];
          _isLoadingMangaDex = false;
          _isOfflineError = true;
        });
      }
    }
  }

  Widget _buildOfflineErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/no_connection.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.wifi_off, size: 80, color: Colors.redAccent);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              "no connection",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Unable to reach MangaDex. Please check your internet connection.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _performMangaDexSearch,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
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
      final bool matchesStatus = _selectedStatusFilter == null || manga.status == _selectedStatusFilter;

      return matchesText && matchesTags && matchesRating && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Search"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: <Widget>[
          const SizedBox(height: 12),
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
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text("All Statuses"),
                              selected: _selectedStatusFilter == null,
                              onSelected: (_) => setState(() => _selectedStatusFilter = null),
                            ),
                            const SizedBox(width: 8),
                            ...MangaStatus.values.map((status) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(status.label),
                                  selected: _selectedStatusFilter == status,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedStatusFilter = selected ? status : null;
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => setState(() => _showAdvancedFilters = !_showAdvancedFilters),
                        child: Row(
                          children: <Widget>[
                            Icon(_showAdvancedFilters ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.indigoAccent),
                            const SizedBox(width: 8),
                            Text(
                              "Advanced Filters (${_filterTags.length + (_minRating > 0 ? 1 : 0)} active)",
                              style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _mangadexSearchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performMangaDexSearch(),
                decoration: InputDecoration(
                  hintText: "Search MangaDex online...",
                  prefixIcon: const Icon(Icons.travel_explore),
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
                  : _isOfflineError
                      ? _buildOfflineErrorWidget()
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
                                    return MangaDexResultTile(
                                      result: _mangadexResults[index],
                                      collection: mangaCollection,
                                      onStateUpdated: () => setState(() {}),
                                    );
                                  },
                                ),
            ),
          ],
        ],
      ),
    );
  }
}
