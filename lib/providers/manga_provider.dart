import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/manga.dart';
import '../repositories/manga_repository.dart';

class MangaCollectionData extends ChangeNotifier {
  final MangaRepository _repository = MangaRepository();
  MangaSortOption _sortOption = MangaSortOption.lastAdded;
  List<Manga> _mangas = <Manga>[];
  
  // Cache the sorted list to prevent expensive sorting 60 times per second during UI animations
  List<Manga> _sortedMangasCache = <Manga>[];
  bool _needsSorting = true;
  
  Timer? _saveDebouncer;

  MangaCollectionData() {
    _loadData();
  }

  MangaSortOption get sortOption => _sortOption;
  set sortOption(MangaSortOption option) {
    if (_sortOption != option) {
      _sortOption = option;
      _needsSorting = true;
      notifyListeners();
    }
  }

  List<Manga> get mangas {
    if (_needsSorting) {
      _sortedMangasCache = List<Manga>.from(_mangas);
      switch (_sortOption) {
        case MangaSortOption.lastAdded:
          _sortedMangasCache.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case MangaSortOption.lastUpdated:
          _sortedMangasCache.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
          break;
        case MangaSortOption.rating:
          _sortedMangasCache.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case MangaSortOption.title:
          _sortedMangasCache.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          break;
      }
      _needsSorting = false;
    }
    return _sortedMangasCache;
  }

  void _scheduleSave() {
    // A manga was updated. Invalidate the sort cache so it moves to the correct position (e.g. top of Recently Updated)
    _needsSorting = true;
    
    if (_saveDebouncer?.isActive ?? false) _saveDebouncer!.cancel();
    _saveDebouncer = Timer(const Duration(milliseconds: 500), () async {
      await _repository.saveMangas(_mangas);
      // Notify listeners after the debounced save to smoothly reorder the UI list
      // This prevents items from jumping around while the user is actively clicking "+"
      notifyListeners();
    });
  }
  
  Future<void> _loadData() async {
    final loadedMangas = await _repository.loadMangas();
    if (loadedMangas.isNotEmpty) {
      _mangas = loadedMangas;
      for (var manga in _mangas) {
        manga.addListener(_scheduleSave);
      }
    } else {
      _mangas = [
        Manga(
          title: "One Piece",
          currentChapter: 1080,
          synopsis: "Monkey D. Luffy, a boy whose body gained the properties of rubber...",
          themes: ["Adventure", "Fantasy", "Action", "Comedy", "Manga"],
          rating: 9,
          status: MangaStatus.reading,
        )..addListener(_scheduleSave),
      ];
      _scheduleSave();
    }
    _needsSorting = true;
    notifyListeners();
  }

  Future<bool> importData(String jsonString) async {
    final importedMangas = await _repository.importMangasFromJson(jsonString);
    if (importedMangas != null) {
      for (var manga in _mangas) {
        manga.removeListener(_scheduleSave);
      }
      _mangas = importedMangas;
      for (var manga in _mangas) {
        manga.addListener(_scheduleSave);
      }
      _needsSorting = true;
      _scheduleSave();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<String> getExportJson() async {
    return await _repository.exportMangasToJson(_mangas);
  }

  void addManga(Manga manga) {
    _mangas.add(manga);
    manga.addListener(_scheduleSave);
    _needsSorting = true;
    _scheduleSave();
    notifyListeners();
  }

  void deleteManga(Manga manga) {
    manga.removeListener(_scheduleSave);
    _mangas.remove(manga);
    _needsSorting = true;
    _scheduleSave();
    notifyListeners();
  }
}
