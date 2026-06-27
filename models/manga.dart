import 'package:flutter/foundation.dart';
import '../core/constants.dart';

enum MangaSortOption {
  lastAdded,
  lastUpdated,
  rating,
  title,
}

class Manga extends ChangeNotifier {
  String title;
  int currentChapter;
  String? imagePath; // Local path to the image
  String synopsis;
  List<String> themes;
  int rating;
  
  final DateTime createdAt;
  DateTime lastUpdated;

  Manga({
    required this.title,
    this.currentChapter = 1,
    this.imagePath,
    this.synopsis = "",
    List<String> themes = const <String>[],
    this.rating = 0,
    DateTime? createdAt,
  })  : themes = _sortTags(themes),
        createdAt = createdAt ?? DateTime.now(),
        lastUpdated = createdAt ?? DateTime.now();

  static List<String> _sortTags(List<String> tagsInput) {
    List<String> sorted = List<String>.from(tagsInput);
    sorted.sort((String a, String b) {
      int getPriority(String tag) {
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
    return sorted;
  }

  void _touch() {
    lastUpdated = DateTime.now();
    notifyListeners();
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

  void updateSynopsis(String newSynopsis) {
    synopsis = newSynopsis;
    _touch();
  }

  void updateThemes(List<String> newThemes) {
    themes = _sortTags(newThemes);
    _touch();
  }

  void updateTitle(String newTitle) {
    if (newTitle.isNotEmpty) {
      title = newTitle;
      _touch();
    }
  }
}

class MangaCollectionData extends ChangeNotifier {
  MangaSortOption _sortOption = MangaSortOption.lastAdded;
  
  final List<Manga> _mangas = <Manga>[
    Manga(
      title: "One Piece",
      currentChapter: 1080,
      imagePath: null, // Initial local data is null
      synopsis: "Monkey D. Luffy, a boy whose body gained the properties of rubber...",
      themes: <String>["Adventure", "Fantasy", "Action", "Comedy", "Manga"],
      rating: 9,
    ),
  ];

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

  void addManga(Manga manga) {
    _mangas.add(manga);
    notifyListeners();
  }

  void deleteManga(Manga manga) {
    _mangas.remove(manga);
    notifyListeners();
  }
}
