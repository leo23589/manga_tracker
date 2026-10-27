import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/manga.dart';

class AniListSearchResult {
  final int id;
  final String title;
  final String synopsis;
  final String? coverUrl;
  final List<String> tags;
  final List<String> altTitles;

  AniListSearchResult({
    required this.id,
    required this.title,
    required this.synopsis,
    this.coverUrl,
    required this.tags,
    required this.altTitles,
  });

  Future<Manga> toMangaWithLocalCover() async {
    final String? localPath = await AniListService.downloadCoverImageLocally(coverUrl);
    return Manga(
      title: title,
      synopsis: synopsis,
      imagePath: localPath ?? coverUrl,
      themes: tags,
      currentChapter: 1,
      rating: 0,
      anilistId: id,
      altTitles: altTitles,
    );
  }
}

class AniListService {
  static const String _graphqlUrl = 'https://graphql.anilist.co';

  static Future<String?> downloadCoverImageLocally(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    try {
      final http.Response response = await http.get(Uri.parse(imageUrl)).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = 'anilist_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File localFile = File('${appDir.path}/$fileName');
        await localFile.writeAsBytes(response.bodyBytes);
        return localFile.path;
      }
    } catch (e) {
      debugPrint('Error downloading AniList cover image: $e');
    }
    return imageUrl;
  }

  /// Fetches cover image URL directly by AniList [mediaId].
  static Future<String?> getCoverByMediaId(int mediaId) async {
    const String queryBody = '''
    query (\$id: Int) {
      Media(id: \$id, type: MANGA) {
        id
        coverImage {
          extraLarge
          large
          medium
        }
      }
    }
    ''';

    try {
      final http.Response response = await http.post(
        Uri.parse(_graphqlUrl),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'query': queryBody,
          'variables': {'id': mediaId},
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final Map<String, dynamic>? coverMap = body['data']?['Media']?['coverImage'] as Map<String, dynamic>?;
        if (coverMap != null) {
          return coverMap['extraLarge'] as String? ?? coverMap['large'] as String?;
        }
      }
    } catch (e) {
      debugPrint('Error fetching AniList cover by ID: $e');
    }
    return null;
  }

  static Future<List<AniListSearchResult>> searchManga(String query) async {
    if (query.trim().isEmpty) return <AniListSearchResult>[];

    const String queryBody = '''
    query (\$search: String) {
      Page(page: 1, perPage: 20) {
        media(search: \$search, type: MANGA) {
          id
          title {
            english
            romaji
            native
          }
          description
          coverImage {
            large
            medium
          }
          genres
          synonyms
          format
        }
      }
    }
    ''';

    try {
      final http.Response response = await http.post(
        Uri.parse(_graphqlUrl),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'query': queryBody,
          'variables': {'search': query.trim()},
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('AniList API error: ${response.statusCode}');
        return <AniListSearchResult>[];
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      final List<dynamic> mediaList = body['data']?['Page']?['media'] ?? <dynamic>[];

      final List<AniListSearchResult> results = <AniListSearchResult>[];

      for (final dynamic item in mediaList) {
        if (item is! Map<String, dynamic>) continue;

        final int id = item['id'] as int? ?? 0;
        final Map<String, dynamic> titleMap = item['title'] as Map<String, dynamic>? ?? {};

        final String english = titleMap['english'] as String? ?? '';
        final String romaji = titleMap['romaji'] as String? ?? '';
        final String native = titleMap['native'] as String? ?? '';

        final String primaryTitle = english.isNotEmpty
            ? english
            : (romaji.isNotEmpty ? romaji : (native.isNotEmpty ? native : 'Untitled'));

        final List<String> altList = <String>[];
        if (english.isNotEmpty && english.toLowerCase() != primaryTitle.toLowerCase()) altList.add(english);
        if (romaji.isNotEmpty && romaji.toLowerCase() != primaryTitle.toLowerCase()) altList.add(romaji);
        if (native.isNotEmpty && native.toLowerCase() != primaryTitle.toLowerCase()) altList.add(native);

        final dynamic synonyms = item['synonyms'];
        if (synonyms is List) {
          for (final dynamic s in synonyms) {
            if (s != null && s.toString().trim().isNotEmpty) {
              final String syn = s.toString().trim();
              if (syn.toLowerCase() != primaryTitle.toLowerCase() && !altList.contains(syn)) {
                altList.add(syn);
              }
            }
          }
        }

        String rawSynopsis = item['description'] as String? ?? '';
        rawSynopsis = rawSynopsis.replaceAll(RegExp(r'<[^>]*>'), '');

        String? coverUrl;
        final Map<String, dynamic>? coverMap = item['coverImage'] as Map<String, dynamic>?;
        if (coverMap != null) {
          coverUrl = coverMap['large'] as String? ?? coverMap['medium'] as String?;
        }

        final List<String> genresList = <String>[];
        final dynamic rawGenres = item['genres'];
        if (rawGenres is List) {
          for (final dynamic g in rawGenres) {
            if (g != null && g.toString().isNotEmpty) {
              genresList.add(g.toString());
            }
          }
        }

        final String? format = item['format'] as String?;
        if (format != null && format.toUpperCase() == 'MANHWA') {
          genresList.insert(0, 'Manhwa');
        } else {
          genresList.insert(0, 'Manga');
        }

        if (!genresList.contains('AniList')) genresList.add('AniList');

        results.add(AniListSearchResult(
          id: id,
          title: primaryTitle,
          synopsis: rawSynopsis,
          coverUrl: coverUrl,
          tags: genresList,
          altTitles: altList,
        ));
      }

      return results;
    } catch (e) {
      debugPrint('Error searching AniList: $e');
      return <AniListSearchResult>[];
    }
  }
}
