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
  bool isOfflineError = false;

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
              isOfflineError = false;
            });

            try {
              final List<MangaDexSearchResult> res = await MangaDexService.searchManga(query);

              if (context.mounted) {
                setState(() {
                  results = res;
                  isLoading = false;
                  isOfflineError = false;
                });
              }
            } catch (e) {
              if (context.mounted) {
                setState(() {
                  results = <MangaDexSearchResult>[];
                  isLoading = false;
                  isOfflineError = true;
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
                      Icon(Icons.auto_awesome, color: Colors.indigoAccent),
                      SizedBox(width: 8),
                      Text("Autofill from MangaDex", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Manga title...",
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
                          : isOfflineError
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/no_connection.png',
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.wifi_off, size: 50, color: Colors.redAccent);
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      const Text("no connection", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: performSearch,
                                        icon: const Icon(Icons.refresh, size: 16),
                                        label: const Text("Retry"),
                                      ),
                                    ],
                                  ),
                                )
                              : !hasSearched
                                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text("Type a title and press search.")))
                                  : results.isEmpty
                                      ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text("No results found.")))
                                      : ListView.builder(
                                          shrinkWrap: true,
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
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text("Cancel"),
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
