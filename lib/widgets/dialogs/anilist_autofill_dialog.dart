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

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.cyanAccent),
                      SizedBox(width: 8),
                      Text('Autofill from AniList', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search AniList Title...',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: performSearch,
                      ),
                    ),
                    onSubmitted: (_) => performSearch(),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: isLoading
                          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                          : !hasSearched
                              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text("Type a title to search AniList")))
                              : searchResults.isEmpty
                                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text("No titles found on AniList.")))
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
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
