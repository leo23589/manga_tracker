import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants.dart';

enum MangaSortOption {
  lastAdded,
  lastUpdated,
  rating,
  title,
}

enum MangaStatus {
  reading,
  finished,
  onHold,
  dropped,
  planToRead,
}

extension MangaStatusExtension on MangaStatus {
  String get label {
    switch (this) {
      case MangaStatus.reading:
        return 'Reading';
      case MangaStatus.finished:
        return 'Finished';
      case MangaStatus.onHold:
        return 'On Hold';
      case MangaStatus.dropped:
        return 'Dropped';
      case MangaStatus.planToRead:
        return 'Plan to Read';
    }
  }

  static MangaStatus fromString(String? val) {
    if (val == null) return MangaStatus.reading;
    return MangaStatus.values.firstWhere(
      (e) => e.label.toLowerCase() == val.toLowerCase() || e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => MangaStatus.reading,
    );
  }
}

class Manga extends ChangeNotifier {
  String title;
  int currentChapter;
  String? imagePath;
  String synopsis;
  List<String> themes;
  int rating;
  MangaStatus status;
  String? mangadexId;
  int? anilistId;
  List<String> altTitles;
  List<String> sourceUrls;
  
  final DateTime createdAt;
  DateTime lastUpdated;

  Manga({
    required this.title,
    this.currentChapter = 1,
    this.imagePath,
    this.synopsis = "",
    List<String> themes = const <String>[],
    this.rating = 0,
    this.status = MangaStatus.reading,
    this.mangadexId,
    this.anilistId,
    List<String>? altTitles,
    List<String>? sourceUrls,
    DateTime? createdAt,
    DateTime? lastUpdated,
  })  : themes = _sortTags(themes, mangadexId, anilistId),
        altTitles = _deduplicateStrings(altTitles ?? <String>[], title),
        sourceUrls = sourceUrls ?? <String>[],
        createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? createdAt ?? DateTime.now();

  bool get isMangaDexLinked => mangadexId != null && mangadexId!.isNotEmpty;
  bool get isAniListLinked => anilistId != null;
  bool get isLinked => isMangaDexLinked || isAniListLinked;

  String get displayTitle => title.trim();

  static List<String> _deduplicateStrings(List<String> list, String primary) {
    final Set<String> unique = <String>{};
    for (final String item in list) {
      final String clean = item.trim();
      if (clean.isNotEmpty && clean.toLowerCase() != primary.trim().toLowerCase()) {
        if (!unique.any((u) => u.toLowerCase() == clean.toLowerCase())) {
          unique.add(clean);
        }
      }
    }
    return unique.toList();
  }

  static List<String> _sortTags(List<String> tagsInput, String? mId, int? aId) {
    List<String> sorted = List<String>.from(tagsInput);

    sorted.removeWhere((t) => t.toLowerCase() == 'long strip');
    sorted.remove("Linked");

    if (mId != null && mId.isNotEmpty) {
      if (!sorted.contains("MangaDex")) sorted.add("MangaDex");
    } else {
      sorted.remove("MangaDex");
    }

    if (aId != null) {
      if (!sorted.contains("AniList")) sorted.add("AniList");
    } else {
      sorted.remove("AniList");
    }

    if (sorted.contains("Manhwa")) {
      sorted.remove("Manga");
      sorted.remove("Manhua");
    } else if (sorted.contains("Manhua")) {
      sorted.remove("Manga");
    } else if (!sorted.any((t) => AppConstants.content.contains(t))) {
      sorted.insert(0, "Manga");
    }

    final Set<String> uniqueTags = <String>{};
    final List<String> deduped = <String>[];
    for (final String t in sorted) {
      if (!uniqueTags.contains(t.toLowerCase())) {
        uniqueTags.add(t.toLowerCase());
        deduped.add(t);
      }
    }

    deduped.sort((String a, String b) {
      int getPriority(String tag) {
        if (tag == "MangaDex" || tag == "AniList") return -1;
        if (AppConstants.content.contains(tag)) return 0;
        if (AppConstants.themes.contains(tag)) return 1;
        if (AppConstants.genres.contains(tag)) return 2;
        return 3;
      }
      int priorityA = getPriority(a);
      int priorityB = getPriority(b);
      if (priorityA != priorityB) return priorityA.compareTo(priorityB);
      return a.compareTo(b);
    });
    return deduped;
  }

  void mergeMangaDetails({
    String? newTitle,
    String? newSynopsis,
    List<String>? newTags,
    List<String>? newAltTitles,
    String? newMangaDexId,
    int? newAniListId,
    String? newCoverPath,
  }) {
    if (newTitle != null && newTitle.trim().isNotEmpty) {
      title = newTitle.trim();
    }

    if (newSynopsis != null && newSynopsis.trim().isNotEmpty) {
      if (synopsis.isEmpty || newSynopsis.length > synopsis.length) {
        synopsis = newSynopsis.trim();
      }
    }

    if (newMangaDexId != null) mangadexId = newMangaDexId;
    if (newAniListId != null) anilistId = newAniListId;

    altTitles = _deduplicateStrings([...altTitles, ...?newAltTitles], title);
    themes = _sortTags([...themes, ...?newTags], mangadexId, anilistId);

    if (newCoverPath != null && newCoverPath.isNotEmpty) {
      imagePath = newCoverPath;
    }

    _touch();
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'currentChapter': currentChapter,
      'imagePath': imagePath,
      'synopsis': synopsis,
      'themes': themes,
      'rating': rating,
      'status': status.label,
      'mangadexId': mangadexId,
      'anilistId': anilistId,
      'altTitles': altTitles,
      'sourceUrls': sourceUrls,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory Manga.fromMap(Map<String, dynamic> map) {
    return Manga(
      title: map['title'],
      currentChapter: map['currentChapter'],
      imagePath: map['imagePath'],
      synopsis: map['synopsis'] ?? '',
      themes: List<String>.from(map['themes'] ?? <String>[]),
      rating: map['rating'] ?? 0,
      status: MangaStatusExtension.fromString(map['status']),
      mangadexId: map['mangadexId'],
      anilistId: map['anilistId'],
      altTitles: List<String>.from(map['altTitles'] ?? <String>[]),
      sourceUrls: List<String>.from(map['sourceUrls'] ?? <String>[]),
      createdAt: DateTime.parse(map['createdAt']),
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  void _touch() {
    lastUpdated = DateTime.now();
    notifyListeners();
  }

  void addSourceUrl(String? url) {
    if (url == null || url.trim().isEmpty) return;
    try {
      final String cleanUrl = url.trim();
      final Uri uri = Uri.parse(cleanUrl);
      final String host = uri.host.toLowerCase();
      if (!sourceUrls.any((s) => s.toLowerCase().contains(host))) {
        sourceUrls.add(cleanUrl);
        _touch();
      }
    } catch (_) {}
  }

  void updateAltTitles(List<String> newAltTitles) {
    altTitles = _deduplicateStrings(newAltTitles, title);
    _touch();
  }

  void updateMangaDexId(String? id) {
    mangadexId = id;
    themes = _sortTags(themes, mangadexId, anilistId);
    _touch();
  }

  void updateAniListId(int? id) {
    anilistId = id;
    themes = _sortTags(themes, mangadexId, anilistId);
    _touch();
  }

  void updateImage(String? newPath) {
    imagePath = newPath;
    _touch();
  }

  void updateChapter(int newChapter) {
    if (newChapter >= 0) {
      currentChapter = newChapter;
      _touch();
    }
  }

  void updateRating(int newRating) {
    if (newRating >= 0 && newRating <= 10) {
      rating = newRating;
      _touch();
    }
  }

  void updateStatus(MangaStatus newStatus) {
    status = newStatus;
    _touch();
  }

  void updateSynopsis(String newSynopsis) {
    synopsis = newSynopsis;
    _touch();
  }

  void updateThemes(List<String> newThemes) {
    themes = _sortTags(newThemes, mangadexId, anilistId);
    _touch();
  }

  void updateTitle(String newTitle) {
    if (newTitle.isNotEmpty) {
      title = newTitle;
      altTitles = _deduplicateStrings(altTitles, title);
      _touch();
    }
  }
}

class MangaCollectionData extends ChangeNotifier {
  MangaSortOption _sortOption = MangaSortOption.lastAdded;
  List<Manga> _mangas = <Manga>[];

  MangaCollectionData() {
    _loadData();
  }

  MangaSortOption get sortOption => _sortOption;
  set sortOption(MangaSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  List<Manga> get mangas {
    List<Manga> sortedList = List<Manga>.from(_mangas);
    switch (_sortOption) {
      case MangaSortOption.lastAdded:
        sortedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case MangaSortOption.lastUpdated:
        sortedList.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        break;
      case MangaSortOption.rating:
        sortedList.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case MangaSortOption.title:
        sortedList.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    return sortedList;
  }

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/mangas.json');
  }

  Future<void> _saveData() async {
    final file = await _localFile;
    final String jsonString = jsonEncode(_mangas.map((m) => m.toMap()).toList());
    await file.writeAsString(jsonString);
  }

  Future<void> _loadData() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final String jsonString = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _mangas = jsonList.map((m) => Manga.fromMap(m)).toList();
        
        for (var manga in _mangas) {
          manga.addListener(_saveData);
        }
        
        notifyListeners();
      } else {
        _mangas = [
          Manga(
            title: "One Piece",
            currentChapter: 1080,
            synopsis: "Monkey D. Luffy, a boy whose body gained the properties of rubber...",
            themes: ["Adventure", "Fantasy", "Action", "Comedy", "Manga"],
            rating: 9,
            status: MangaStatus.reading,
          )..addListener(_saveData),
        ];
        await _saveData();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement : $e");
    }
  }

  Future<bool> importData(String jsonString) async {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final Directory appDir = await getApplicationDocumentsDirectory();

      final List<Manga> newMangas = <Manga>[];

      for (final dynamic item in jsonList) {
        if (item is! Map<String, dynamic>) continue;

        String? restoredImagePath = item['imagePath'] as String?;
        final String? imageBase64 = item['imageBase64'] as String?;

        if (imageBase64 != null && imageBase64.isNotEmpty) {
          try {
            final List<int> bytes = base64Decode(imageBase64);
            final String fileName = 'imported_cover_${DateTime.now().millisecondsSinceEpoch}_${newMangas.length}.jpg';
            final File file = File('${appDir.path}/$fileName');
            await file.writeAsBytes(bytes);
            restoredImagePath = file.path;
          } catch (e) {
            debugPrint('Failed to decode imported image: $e');
          }
        }

        final Map<String, dynamic> mangaMap = Map<String, dynamic>.from(item);
        mangaMap['imagePath'] = restoredImagePath;

        newMangas.add(Manga.fromMap(mangaMap));
      }

      for (var manga in _mangas) {
        manga.removeListener(_saveData);
      }

      _mangas = newMangas;
      for (var manga in _mangas) {
        manga.addListener(_saveData);
      }
      
      await _saveData();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Erreur d'importation : $e");
      return false;
    }
  }

  Future<String> getExportJson() async {
    final List<Map<String, dynamic>> exportList = <Map<String, dynamic>>[];

    for (final Manga manga in _mangas) {
      final Map<String, dynamic> map = manga.toMap();

      if (manga.imagePath != null && manga.imagePath!.isNotEmpty) {
        if (File(manga.imagePath!).existsSync()) {
          try {
            final List<int> bytes = await File(manga.imagePath!).readAsBytes();
            map['imageBase64'] = base64Encode(bytes);
          } catch (e) {
            debugPrint('Failed to encode image to base64: $e');
          }
        }
      }

      exportList.add(map);
    }

    return jsonEncode(exportList);
  }

  void addManga(Manga manga) {
    _mangas.add(manga);
    manga.addListener(_saveData);
    _saveData();
    notifyListeners();
  }

  void deleteManga(Manga manga) {
    manga.removeListener(_saveData);
    _mangas.remove(manga);
    _saveData();
    notifyListeners();
  }
}
