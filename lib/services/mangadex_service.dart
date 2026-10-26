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
    final List<String> updatedTags = List<String>.from(tags);
    if (!updatedTags.contains("Linked")) {
      updatedTags.add("Linked");
    }
    return Manga(
      title: title,
      synopsis: synopsis,
      imagePath: coverUrl,
      themes: updatedTags,
      currentChapter: 1,
      rating: 0,
    );
  }

  Future<Manga> toMangaWithLocalCover() async {
    final String? localPath = await MangaDexService.downloadCoverImageLocally(coverUrl);
    final List<String> updatedTags = List<String>.from(tags);
    if (!updatedTags.contains("Linked")) {
      updatedTags.add("Linked");
    }
    return Manga(
      title: title,
      synopsis: synopsis,
      imagePath: localPath ?? coverUrl,
      themes: updatedTags,
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

  /// Searches MangaDex and returns a list of cover art URLs for the matching manga (ONLY covers, no names).
  static Future<List<String>> getMangaCoverUrls(String query) async {
    if (query.trim().isEmpty) return <String>[];

    try {
      final results = await searchManga(query);
      if (results.isEmpty) return <String>[];

      final String mangaId = results.first.id;

      final Uri uri = Uri.parse('$_baseUrl/cover').replace(
        queryParameters: <String, String>{
          'manga[]': mangaId,
          'limit': '100',
          'order[volume]': 'desc',
        },
      );

      final http.Response response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        if (results.first.coverUrl != null) {
          return [results.first.coverUrl!];
        }
        return <String>[];
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      final List<dynamic> data = body['data'] ?? <dynamic>[];

      final List<String> coverUrls = <String>[];
      for (final dynamic item in data) {
        if (item is Map && item['attributes'] is Map) {
          final String? fileName = item['attributes']['fileName'] as String?;
          if (fileName != null && fileName.isNotEmpty) {
            coverUrls.add('https://uploads.mangadex.org/covers/$mangaId/$fileName.512.jpg');
          }
        }
      }

      if (coverUrls.isEmpty && results.first.coverUrl != null) {
        coverUrls.add(results.first.coverUrl!);
      }

      return coverUrls;
    } catch (e) {
      debugPrint('Error fetching cover art URLs: $e');
      return <String>[];
    }
  }

  /// Extracts the preferred English title from MangaDex attributes,
  /// falling back to Romanized Japanese or first available title.
  static String _extractEnglishTitle(Map<String, dynamic> attributes) {
    final dynamic titleObj = attributes['title'];
    if (titleObj is Map && titleObj['en'] != null) {
      final String en = titleObj['en'].toString().trim();
      if (en.isNotEmpty) return en;
    }

    final dynamic altTitles = attributes['altTitles'];
    if (altTitles is List) {
      for (final dynamic alt in altTitles) {
        if (alt is Map && alt['en'] != null) {
          final String en = alt['en'].toString().trim();
          if (en.isNotEmpty) return en;
        }
      }
    }

    if (titleObj is Map && titleObj['ja-ro'] != null) {
      final String jaRo = titleObj['ja-ro'].toString().trim();
      if (jaRo.isNotEmpty) return jaRo;
    }
    if (altTitles is List) {
      for (final dynamic alt in altTitles) {
        if (alt is Map && alt['ja-ro'] != null) {
          final String jaRo = alt['ja-ro'].toString().trim();
          if (jaRo.isNotEmpty) return jaRo;
        }
      }
    }

    if (titleObj is Map && titleObj.values.isNotEmpty) {
      for (final dynamic val in titleObj.values) {
        if (val != null && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
      }
    }

    if (altTitles is List) {
      for (final dynamic alt in altTitles) {
        if (alt is Map && alt.values.isNotEmpty) {
          for (final dynamic val in alt.values) {
            if (val != null && val.toString().trim().isNotEmpty) {
              return val.toString().trim();
            }
          }
        }
      }
    }

    return 'Untitled';
  }

  /// Extracts the preferred English synopsis/description from MangaDex attributes.
  static String _extractEnglishSynopsis(Map<String, dynamic> attributes) {
    final dynamic descObj = attributes['description'];
    if (descObj is Map) {
      if (descObj['en'] != null && descObj['en'].toString().trim().isNotEmpty) {
        return descObj['en'].toString().trim();
      }
      for (final dynamic val in descObj.values) {
        if (val != null && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
      }
    }
    return '';
  }

  /// Searches MangaDex for manga matching [query] in any language.
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

        final String title = _extractEnglishTitle(attributes);
        final String synopsis = _extractEnglishSynopsis(attributes);

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

        final String? demographic = attributes['publicationDemographic'] as String?;
        if (demographic != null && demographic.isNotEmpty) {
          final String demoCapitalized = demographic[0].toUpperCase() + demographic.substring(1);
          if (!extractedTags.contains(demoCapitalized)) {
            extractedTags.add(demoCapitalized);
          }
        }

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
      rethrow;
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
