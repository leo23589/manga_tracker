import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/manga.dart';
import '../repositories/manga_repository.dart';

class MangaCollectionData extends ChangeNotifier {
  final MangaRepository _repository = MangaRepository();
  MangaSortOption _sortOption = MangaSortOption.lastAdded;
  List<Manga> _mangas = <Manga>[];
  
  Timer? _saveDebouncer;

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

  void _scheduleSave() {
    if (_saveDebouncer?.isActive ?? false) _saveDebouncer!.cancel();
    _saveDebouncer = Timer(const Duration(milliseconds: 500), () async {
      await _repository.saveMangas(_mangas);
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
    _scheduleSave();
    notifyListeners();
  }

  void deleteManga(Manga manga) {
    manga.removeListener(_scheduleSave);
    _mangas.remove(manga);
    _scheduleSave();
    notifyListeners();
  }
}
