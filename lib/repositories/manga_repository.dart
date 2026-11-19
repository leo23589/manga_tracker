import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/manga.dart';

class MangaRepository {
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/mangas.json');
  }

  static String _encodeMangaList(List<Map<String, dynamic>> maps) {
    return jsonEncode(maps);
  }

  static List<dynamic> _decodeMangaList(String jsonString) {
    return jsonDecode(jsonString);
  }

  Future<void> saveMangas(List<Manga> mangas) async {
    try {
      final file = await _localFile;
      final String jsonString = await compute(_encodeMangaList, mangas.map((m) => m.toMap()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint("Error saving to MangaRepository: $e");
    }
  }

  Future<List<Manga>> loadMangas() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final String jsonString = await file.readAsString();
        final List<dynamic> jsonList = await compute(_decodeMangaList, jsonString);
        return jsonList.map((m) => Manga.fromMap(m)).toList();
      }
    } catch (e) {
      debugPrint("Error loading from MangaRepository: $e");
    }
    return <Manga>[];
  }

  Future<List<Manga>?> importMangasFromJson(String jsonString) async {
    try {
      final List<dynamic> jsonList = await compute(_decodeMangaList, jsonString);
      final Directory appDir = await getApplicationDocumentsDirectory();

      final List<Manga> importedMangas = <Manga>[];

      for (final dynamic item in jsonList) {
        if (item is! Map<String, dynamic>) continue;

        String? restoredImagePath = item['imagePath'] as String?;
        final String? imageBase64 = item['imageBase64'] as String?;

        if (imageBase64 != null && imageBase64.isNotEmpty) {
          try {
            final List<int> bytes = base64Decode(imageBase64);
            final String fileName = 'imported_cover_${DateTime.now().millisecondsSinceEpoch}_${importedMangas.length}.jpg';
            final File file = File('${appDir.path}/$fileName');
            await file.writeAsBytes(bytes);
            restoredImagePath = file.path;
          } catch (e) {
            debugPrint('Failed to decode imported image: $e');
          }
        }

        final Map<String, dynamic> mangaMap = Map<String, dynamic>.from(item);
        mangaMap['imagePath'] = restoredImagePath;
        importedMangas.add(Manga.fromMap(mangaMap));
      }
      return importedMangas;
    } catch (e) {
      debugPrint("Error importing to MangaRepository: $e");
      return null;
    }
  }

  Future<String> exportMangasToJson(List<Manga> mangas) async {
    final List<Map<String, dynamic>> exportList = <Map<String, dynamic>>[];
    for (final Manga manga in mangas) {
      final Map<String, dynamic> map = manga.toMap();
      if (manga.imagePath != null && manga.imagePath!.isNotEmpty) {
        if (File(manga.imagePath!).existsSync()) {
          try {
            final List<int> bytes = await File(manga.imagePath!).readAsBytes();
            map['imageBase64'] = base64Encode(bytes);
          } catch (e) {
            debugPrint('Failed to encode image to base64 for export: $e');
          }
        }
      }
      exportList.add(map);
    }
    return await compute(_encodeMangaList, exportList);
  }
}
