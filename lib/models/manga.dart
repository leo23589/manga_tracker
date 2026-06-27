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

class Manga extends ChangeNotifier {
  String title;
  int currentChapter;
  String? imagePath;
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
    DateTime? lastUpdated,
  })  : themes = _sortTags(themes),
        createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? createdAt ?? DateTime.now();

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

  // Convertir un Manga en Map (pour le JSON)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'currentChapter': currentChapter,
      'imagePath': imagePath,
      'synopsis': synopsis,
      'themes': themes,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Créer un Manga à partir d'un Map
  factory Manga.fromMap(Map<String, dynamic> map) {
    return Manga(
      title: map['title'],
      currentChapter: map['currentChapter'],
      imagePath: map['imagePath'],
      synopsis: map['synopsis'],
      themes: List<String>.from(map['themes']),
      rating: map['rating'],
      createdAt: DateTime.parse(map['createdAt']),
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
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
  List<Manga> _mangas = <Manga>[];

  MangaCollectionData() {
    _loadData(); // Charger les données dès la création
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

  // Fichier de sauvegarde
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/mangas.json');
  }

  // Sauvegarder les données
  Future<void> _saveData() async {
    final file = await _localFile;
    final String jsonString = jsonEncode(_mangas.map((m) => m.toMap()).toList());
    await file.writeAsString(jsonString);
  }

  // Charger les données
  Future<void> _loadData() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final String jsonString = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _mangas = jsonList.map((m) => Manga.fromMap(m)).toList();
        
        // Ajouter des listeners pour sauvegarder si un manga individuel change
        for (var manga in _mangas) {
          manga.addListener(_saveData);
        }
        
        notifyListeners();
      } else {
        // Données par défaut si premier lancement
        _mangas = [
          Manga(
            title: "One Piece",
            currentChapter: 1080,
            synopsis: "Monkey D. Luffy, a boy whose body gained the properties of rubber...",
            themes: ["Adventure", "Fantasy", "Action", "Comedy", "Manga"],
            rating: 9,
          )..addListener(_saveData),
        ];
        await _saveData();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement : $e");
    }
  }

  // Importer depuis un JSON externe
  Future<bool> importData(String jsonString) async {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<Manga> newMangas = jsonList.map((m) => Manga.fromMap(m)).toList();
      
      // Nettoyer les anciens listeners
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

  // Récupérer le contenu JSON actuel pour l'export
  Future<String> getExportJson() async {
    return jsonEncode(_mangas.map((m) => m.toMap()).toList());
  }

  void addManga(Manga manga) {
    _mangas.add(manga);
    manga.addListener(_saveData); // Sauvegarder quand ce manga change
    _saveData(); // Sauvegarder la liste
    notifyListeners();
  }

  void deleteManga(Manga manga) {
    manga.removeListener(_saveData);
    _mangas.remove(manga);
    _saveData();
    notifyListeners();
  }
}
