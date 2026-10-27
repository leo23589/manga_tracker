import 'package:flutter/material.dart';
import '../../services/anilist_service.dart';
import '../manga_cover_image.dart';

void showAniListAutofillDialog({
  required BuildContext parentContext,
  required String initialQuery,
  required Function(AniListSearchResult result) onSelect,
}) {
  final TextEditingController searchController = TextEditingController(text: initialQuery);
  List<AniListSearchResult> searchResults = <AniListSearchResult>[];
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

            try {
              final results = await AniListService.searchManga(query);
              if (context.mounted) {
                setState(() {
                  searchResults = results;
                  isLoading = false;
                });
              }
            } catch (e) {
              if (context.mounted) {
                setState(() {
                  searchResults = <AniListSearchResult>[];
                  isLoading = false;
                });
              }
            }
          }

          if (!hasSearched && initialQuery.trim().isNotEmpty) {
            performSearch();
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.cyanAccent),
                SizedBox(width: 8),
                Text('Autofill from AniList'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search AniList Title',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: performSearch,
                      ),
                    ),
                    onSubmitted: (_) => performSearch(),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : !hasSearched
                            ? const Center(child: Text("Type a title to search AniList"))
                            : searchResults.isEmpty
                                ? const Center(child: Text("No titles found on AniList."))
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: searchResults.length,
                                    itemBuilder: (context, index) {
                                      final item = searchResults[index];
                                      return ListTile(
                                        leading: MangaCoverImage(
                                          imagePath: item.coverUrl,
                                          width: 40,
                                          height: 60,
                                          borderRadius: 6,
                                        ),
                                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        subtitle: Text(
                                          item.synopsis.isEmpty ? "No synopsis" : item.synopsis,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        onTap: () {
                                          Navigator.of(dialogContext).pop();
                                          onSelect(item);
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
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    },
  );
}
