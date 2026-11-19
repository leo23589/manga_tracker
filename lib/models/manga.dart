import 'package:flutter/foundation.dart';
import '../utils/manga_utils.dart';

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
  })  : themes = MangaUtils.sortTags(themes, mangadexId, anilistId),
        altTitles = MangaUtils.deduplicateStrings(altTitles ?? <String>[], title),
        sourceUrls = MangaUtils.deduplicateUrls(sourceUrls ?? <String>[]),
        createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? createdAt ?? DateTime.now();

  bool get isMangaDexLinked => mangadexId != null && mangadexId!.isNotEmpty;
  bool get isAniListLinked => anilistId != null;
  bool get isLinked => isMangaDexLinked || isAniListLinked;

  String get displayTitle => title.trim();

  void mergeMangaDetails({
    String? newTitle,
    String? newSynopsis,
    List<String>? newTags,
    List<String>? newAltTitles,
    String? newMangaDexId,
    int? newAniListId,
    String? newCoverPath,
  }) {
    final List<String> candidateTitles = <String>[];
    if (newTitle != null && newTitle.trim().isNotEmpty) candidateTitles.add(newTitle.trim());
    if (newAltTitles != null) candidateTitles.addAll(newAltTitles.map((e) => e.trim()));

    String bestTitle = title;
    for (final String cand in candidateTitles) {
      if (MangaUtils.looksLikeEnglishTitle(cand)) {
        bestTitle = cand;
        break;
      }
    }
    if (bestTitle == title && newTitle != null && newTitle.trim().isNotEmpty) {
      bestTitle = newTitle.trim();
    }

    final List<String> combinedAltList = <String>[...altTitles, ...?newAltTitles];
    if (bestTitle.toLowerCase() != title.toLowerCase()) {
      combinedAltList.add(title);
    }
    title = bestTitle;

    if (newSynopsis != null && newSynopsis.trim().isNotEmpty) {
      if (synopsis.isEmpty || newSynopsis.length > synopsis.length) {
        synopsis = newSynopsis.trim();
      }
    }

    if (newMangaDexId != null) mangadexId = newMangaDexId;
    if (newAniListId != null) anilistId = newAniListId;

    altTitles = MangaUtils.deduplicateStrings(combinedAltList, title);
    themes = MangaUtils.sortTags([...themes, ...?newTags], mangadexId, anilistId);

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
      final String baseTemplate = MangaUtils.getBaseUrl(url);
      final Uri newUri = Uri.parse(baseTemplate);
      final String newHost = newUri.host;
      
      sourceUrls.removeWhere((s) {
        try {
          return Uri.parse(s).host == newHost;
        } catch (_) {
          return false;
        }
      });
      sourceUrls.add(baseTemplate);
      _touch();
    } catch (_) {}
  }

  void removeSourceUrl(String urlToRemove) {
    sourceUrls.removeWhere((u) => u.trim() == urlToRemove.trim());
    _touch();
  }

  void removeAltTitle(String altToRemove) {
    altTitles.removeWhere((t) => t.trim().toLowerCase() == altToRemove.trim().toLowerCase());
    _touch();
  }

  void updateAltTitles(List<String> newAltTitles) {
    final List<String> combined = <String>[...altTitles, ...newAltTitles];
    altTitles = MangaUtils.deduplicateStrings(combined, title);
    _touch();
  }

  void updateMangaDexId(String? id) {
    mangadexId = id;
    themes = MangaUtils.sortTags(themes, mangadexId, anilistId);
    _touch();
  }

  void updateAniListId(int? id) {
    anilistId = id;
    themes = MangaUtils.sortTags(themes, mangadexId, anilistId);
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
    themes = MangaUtils.sortTags(newThemes, mangadexId, anilistId);
    _touch();
  }

  void updateTitle(String newTitle) {
    if (newTitle.isNotEmpty) {
      final String oldTitle = title;
      title = newTitle;
      altTitles = MangaUtils.deduplicateStrings([...altTitles, oldTitle], title);
      _touch();
    }
  }
}
