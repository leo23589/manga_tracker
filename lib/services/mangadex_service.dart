import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/manga.dart';
import '../core/constants.dart';

class MangaDexSearchResult {
  final String id;
  final String title;
  final String synopsis;
  final String? coverUrl;
  final List<String> tags;

  MangaDexSearchResult({
    required this.id,
    required this.title,
    required this.synopsis,
    this.coverUrl,
    required this.tags,
  });

  Manga toManga() {
    return Manga(
      title: title,
      synopsis: synopsis,
      imagePath: coverUrl,
      themes: tags,
      currentChapter: 1,
      rating: 0,
    );
  }

  Future<Manga> toMangaWithLocalCover() async {
    final String? localPath = await MangaDexService.downloadCoverImageLocally(coverUrl);
    return Manga(
      title: title,
      synopsis: synopsis,
      imagePath: localPath ?? coverUrl,
      themes: tags,
      currentChapter: 1,
      rating: 0,
    );
  }
}

class MangaDexService {
  static const String _baseUrl = 'https://api.mangadex.org';

  /// Downloads a remote cover image URL to local storage so it works 100% offline.
  static Future<String?> downloadCoverImageLocally(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      return imageUrl; // Already a local path
    }

    try {
      final http.Response response = await http.get(Uri.parse(imageUrl)).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File localFile = File('${appDir.path}/$fileName');
        await localFile.writeAsBytes(response.bodyBytes);
        return localFile.path;
      }
    } catch (e) {
      debugPrint('Error downloading cover image locally: $e');
    }
    return imageUrl; // Fallback to URL if download fails
  }

  /// Searches MangaDex for manga matching [query].
  static Future<List<MangaDexSearchResult>> searchManga(String query) async {
    if (query.trim().isEmpty) {
      return <MangaDexSearchResult>[];
    }

    try {
      final Uri uri = Uri.parse('$_baseUrl/manga').replace(
        queryParameters: <String, dynamic>{
          'title': query.trim(),
          'limit': '20',
          'includes[]': 'cover_art',
          'order[relevance]': 'desc',
        },
      );

      final http.Response response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        debugPrint('MangaDex API error: ${response.statusCode}');
        return <MangaDexSearchResult>[];
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      final List<dynamic> data = body['data'] ?? <dynamic>[];

      final List<MangaDexSearchResult> results = <MangaDexSearchResult>[];

      for (final dynamic item in data) {
        if (item is! Map<String, dynamic>) continue;

        final String mangaId = item['id'] as String? ?? '';
        final Map<String, dynamic> attributes = item['attributes'] as Map<String, dynamic>? ?? <String, dynamic>{};

        // Parse Title
        String title = '';
        final dynamic titleObj = attributes['title'];
        if (titleObj is Map) {
          title = titleObj['en'] as String? ??
              titleObj['ja-ro'] as String? ??
              (titleObj.values.isNotEmpty ? titleObj.values.first.toString() : '');
        }

        if (title.isEmpty) {
          final dynamic altTitles = attributes['altTitles'];
          if (altTitles is List && altTitles.isNotEmpty) {
            for (final dynamic alt in altTitles) {
              if (alt is Map && alt.values.isNotEmpty) {
                title = alt.values.first.toString();
                if (title.isNotEmpty) break;
              }
            }
          }
        }

        if (title.isEmpty) {
          title = 'Untitled';
        }

        // Parse Synopsis / Description
        String synopsis = '';
        final dynamic descObj = attributes['description'];
        if (descObj is Map) {
          synopsis = descObj['en'] as String? ??
              (descObj.values.isNotEmpty ? descObj.values.first.toString() : '');
        }

        // Parse Cover Art
        String? coverUrl;
        final dynamic relationships = item['relationships'];
        if (relationships is List) {
          for (final dynamic rel in relationships) {
            if (rel is Map && rel['type'] == 'cover_art') {
              final Map<String, dynamic>? relAttributes = rel['attributes'] as Map<String, dynamic>?;
              if (relAttributes != null) {
                final String? fileName = relAttributes['fileName'] as String?;
                if (fileName != null && fileName.isNotEmpty) {
                  coverUrl = 'https://uploads.mangadex.org/covers/$mangaId/$fileName.256.jpg';
                  break;
                }
              }
            }
          }
        }

        // Parse Tags / Genres
        final List<String> extractedTags = <String>[];
        final dynamic tagsList = attributes['tags'];
        if (tagsList is List) {
          for (final dynamic tagObj in tagsList) {
            if (tagObj is Map) {
              final dynamic tagAttr = tagObj['attributes'];
              if (tagAttr is Map) {
                final dynamic tagNameObj = tagAttr['name'];
                if (tagNameObj is Map) {
                  final String? tagName = tagNameObj['en'] as String?;
                  if (tagName != null) {
                    final String matchedTag = _matchAppTag(tagName);
                    if (!extractedTags.contains(matchedTag)) {
                      extractedTags.add(matchedTag);
                    }
                  }
                }
              }
            }
          }
        }

        // Parse content demographic or format as content tag
        final String? demographic = attributes['publicationDemographic'] as String?;
        if (demographic != null && demographic.isNotEmpty) {
          final String demoCapitalized = demographic[0].toUpperCase() + demographic.substring(1);
          if (!extractedTags.contains(demoCapitalized)) {
            extractedTags.add(demoCapitalized);
          }
        }

        // Ensure at least "Manga" if content is empty
        bool hasContentTag = extractedTags.any((t) => AppConstants.content.contains(t));
        if (!hasContentTag) {
          extractedTags.insert(0, "Manga");
        }

        results.add(MangaDexSearchResult(
          id: mangaId,
          title: title,
          synopsis: synopsis,
          coverUrl: coverUrl,
          tags: extractedTags,
        ));
      }

      return results;
    } catch (e) {
      debugPrint('Error searching MangaDex: $e');
      rethrow; // Rethrow so caller can detect network/connection errors
    }
  }

  static String _matchAppTag(String apiTag) {
    for (final String g in AppConstants.genres) {
      if (g.toLowerCase() == apiTag.toLowerCase()) return g;
    }
    for (final String t in AppConstants.themes) {
      if (t.toLowerCase() == apiTag.toLowerCase()) return t;
    }
    for (final String c in AppConstants.content) {
      if (c.toLowerCase() == apiTag.toLowerCase()) return c;
    }
    return apiTag;
  }
}
