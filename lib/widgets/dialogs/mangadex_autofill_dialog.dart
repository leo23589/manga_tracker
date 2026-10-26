import 'package:flutter/material.dart';
import '../../services/mangadex_service.dart';
import '../manga_cover_image.dart';

void showMangaDexAutofillDialog({
  required BuildContext parentContext,
  required String initialQuery,
  required Function(MangaDexSearchResult) onSelect,
}) {
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
