import 'package:flutter/material.dart';
import '../../services/anilist_service.dart';
import '../../services/mangadex_service.dart';
import '../manga_cover_image.dart';

void showMangaDexCoverPickerDialog({
  required BuildContext parentContext,
  required String mangaTitle,
  String? mangaDexId,
  int? aniListId,
  required Function(String localCoverPath) onSelectCover,
}) {
  List<String> coverUrls = <String>[];
  bool isLoading = true;
  bool isError = false;

  showModalBottomSheet<void>(
    context: parentContext,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext modalContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          Future<void> fetchCovers() async {
            setState(() {
              isLoading = true;
              isError = false;
            });

            try {
              final List<String> combinedCovers = <String>[];

              // 1. Fetch MangaDex Covers
              try {
                final dexCovers = await MangaDexService.getMangaCoverUrls(mangaId: mangaDexId, query: mangaTitle);
                combinedCovers.addAll(dexCovers);
              } catch (_) {}

              // 2. Fetch AniList Covers
              try {
                if (aniListId != null) {
                  final aniCover = await AniListService.getCoverByMediaId(aniListId);
                  if (aniCover != null && !combinedCovers.contains(aniCover)) {
                    combinedCovers.insert(0, aniCover);
                  }
                } else {
                  final aniResults = await AniListService.searchManga(mangaTitle);
                  for (final res in aniResults) {
                    if (res.coverUrl != null && !combinedCovers.contains(res.coverUrl)) {
                      combinedCovers.add(res.coverUrl!);
                    }
                  }
                }
              } catch (_) {}

              if (context.mounted) {
                setState(() {
                  coverUrls = combinedCovers;
                  isLoading = false;
                });
              }
            } catch (e) {
              if (context.mounted) {
                setState(() {
                  isLoading = false;
                  isError = true;
                });
              }
            }
          }

          if (isLoading && coverUrls.isEmpty && !isError) {
            fetchCovers();
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            builder: (BuildContext context, ScrollController scrollController) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Select Cover (MangaDex & AniList)",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : isError
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.wifi_off, size: 60, color: Colors.redAccent),
                                      const SizedBox(height: 12),
                                      const Text("Could not load covers"),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: fetchCovers,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text("Retry"),
                                      ),
                                    ],
                                  ),
                                )
                              : coverUrls.isEmpty
                                  ? const Center(child: Text("No covers found across MangaDex or AniList."))
                                  : GridView.builder(
                                      controller: scrollController,
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        childAspectRatio: 0.68,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                      ),
                                      itemCount: coverUrls.length,
                                      itemBuilder: (context, index) {
                                        final url = coverUrls[index];
                                        return InkWell(
                                          onTap: () async {
                                            Navigator.of(modalContext).pop();
                                            ScaffoldMessenger.of(parentContext).showSnackBar(
                                              const SnackBar(content: Text('Downloading cover...')),
                                            );
                                            final localPath = await MangaDexService.downloadCoverImageLocally(url);
                                            if (localPath != null) {
                                              onSelectCover(localPath);
                                              if (parentContext.mounted) {
                                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Cover image updated!'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: MangaCoverImage(
                                              imagePath: url,
                                              width: double.infinity,
                                              height: double.infinity,
                                              borderRadius: 10,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
