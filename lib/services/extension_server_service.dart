import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/manga.dart';
import 'anilist_service.dart';
import 'mangadex_service.dart';
import 'notification_service.dart';

class ActivityLogEntry {
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isSuccess;

  ActivityLogEntry({
    required this.title,
    required this.message,
    required this.timestamp,
    this.isSuccess = true,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'isSuccess': isSuccess,
      };

  factory ActivityLogEntry.fromMap(Map<String, dynamic> map) => ActivityLogEntry(
        title: map['title'] ?? '',
        message: map['message'] ?? '',
        timestamp: DateTime.parse(map['timestamp']),
        isSuccess: map['isSuccess'] ?? true,
      );
}

class PendingMangaUpdate {
  final String rawTitle;
  String formattedTitle;
  int chapter;
  final bool isChapter;
  final MangaStatus defaultStatus;
  final String? url;
  String? coverUrl;

  PendingMangaUpdate({
    required this.rawTitle,
    required this.formattedTitle,
    required this.chapter,
    required this.isChapter,
    required this.defaultStatus,
    this.url,
    this.coverUrl,
  });
}

class ExtensionServerService extends ChangeNotifier {
  HttpServer? _server;
  bool _isListening = false;
  final int _port = 8080;

  final List<PendingMangaUpdate> _pendingQueue = <PendingMangaUpdate>[];
  final List<ActivityLogEntry> _logs = <ActivityLogEntry>[];
  String? _lastNotificationMessage;

  ExtensionServerService() {
    _loadLogs();
  }

  bool get isListening => _isListening;
  int get port => _port;
  List<PendingMangaUpdate> get pendingQueue => _pendingQueue;
  PendingMangaUpdate? get currentPending => _pendingQueue.isNotEmpty ? _pendingQueue.first : null;
  List<ActivityLogEntry> get logs => List<ActivityLogEntry>.unmodifiable(_logs);
  String? get lastNotificationMessage => _lastNotificationMessage;

  void dismissCurrentPending() {
    if (_pendingQueue.isNotEmpty) {
      _pendingQueue.removeAt(0);
      notifyListeners();
    }
  }

  void updateCurrentPendingChapter(int newChapter) {
    if (_pendingQueue.isNotEmpty && newChapter >= 1) {
      _pendingQueue.first.chapter = newChapter;
      notifyListeners();
    }
  }

  void clearNotificationMessage() {
    _lastNotificationMessage = null;
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    _saveLogs();
    notifyListeners();
  }

  Future<File> get _logFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/extension_logs.json');
  }

  Future<void> _loadLogs() async {
    try {
      final file = await _logFile;
      if (await file.exists()) {
        final String content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _logs.clear();
        _logs.addAll(jsonList.map((e) => ActivityLogEntry.fromMap(e)));
        _purgeOldLogs();
      }
    } catch (e) {
      debugPrint("Error loading logs: $e");
    }
  }

  Future<void> _saveLogs() async {
    try {
      final file = await _logFile;
      final String content = jsonEncode(_logs.map((e) => e.toMap()).toList());
      await file.writeAsString(content);
    } catch (e) {
      debugPrint("Error saving logs: $e");
    }
  }

  void _addLog(String title, String message, {bool isSuccess = true}) {
    _logs.insert(
      0,
      ActivityLogEntry(
        title: title,
        message: message,
        timestamp: DateTime.now(),
        isSuccess: isSuccess,
      ),
    );
    _purgeOldLogs();
    _saveLogs();
    notifyListeners();
  }

  void _purgeOldLogs() {
    final now = DateTime.now();
    _logs.removeWhere((log) => now.difference(log.timestamp).inDays >= 30);
  }

  Future<void> startServer(MangaCollectionData collection) async {
    if (_isListening) return;

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
      _isListening = true;
      notifyListeners();
      debugPrint("ExtensionServerService running on http://127.0.0.1:$_port");

      _server!.listen((HttpRequest request) async {
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization');
        request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');

        if (request.method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          return;
        }

        if (request.method == 'POST' && request.uri.path == '/update') {
          try {
            final String body = await utf8.decoder.bind(request).join();
            final Map<String, dynamic> json = jsonDecode(body);

            final String? rawTitle = json['title'] as String? ?? json['name'] as String?;
            final dynamic chapterVal = json['chapter'];
            final bool isChapter = json['isChapter'] as bool? ?? true;
            final String? url = json['url'] as String?;

            int chapter = 1;
            if (chapterVal is int) {
              chapter = chapterVal;
            } else if (chapterVal is String) {
              chapter = int.tryParse(chapterVal) ?? 1;
            }

            if (rawTitle != null && rawTitle.isNotEmpty) {
              _processChapterUpdate(
                rawTitle: rawTitle,
                chapter: chapter,
                isChapter: isChapter,
                url: url,
                collection: collection,
              );

              request.response
                ..statusCode = HttpStatus.ok
                ..headers.contentType = ContentType.json
                ..write(jsonEncode({'status': 'success', 'title': rawTitle, 'chapter': chapter}));
            } else {
              request.response
                ..statusCode = HttpStatus.badRequest
                ..write(jsonEncode({'error': 'Missing title'}));
            }
          } catch (e) {
            request.response
              ..statusCode = HttpStatus.internalServerError
              ..write(jsonEncode({'error': e.toString()}));
          }
        } else if (request.method == 'GET' && request.uri.path == '/status') {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'status': 'running', 'mangaCount': collection.mangas.length}));
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not Found');
        }

        await request.response.close();
      });
    } catch (e) {
      debugPrint("Failed to start ExtensionServerService on port $_port: $e");
      _isListening = false;
      notifyListeners();
    }
  }

  void stopServer() {
    _server?.close(force: true);
    _server = null;
    _isListening = false;
    notifyListeners();
  }

  static String normalizeTitle(String title) {
    return title
        .replaceAll('\$', '')
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  static String formatTitleFromSlug(String slug) {
    final String clean = slug.replaceAll('-', ' ').replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return slug;
    return clean.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _processChapterUpdate({
    required String rawTitle,
    required int chapter,
    required bool isChapter,
    required String? url,
    required MangaCollectionData collection,
  }) async {
    final String normIncoming = normalizeTitle(rawTitle);
    final String formattedTitle = formatTitleFromSlug(rawTitle);

    String? incomingMangaDexId;
    if (url != null && url.contains('mangadex.org')) {
      final match = RegExp(r'/(?:title|manga|chapter)/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})', caseSensitive: false).firstMatch(url);
      if (match != null) {
        incomingMangaDexId = match.group(1);
      }
    }

    // 1. Direct Search in Local Collection
    Manga? matchedManga;
    for (final Manga m in collection.mangas) {
      if (incomingMangaDexId != null && m.mangadexId == incomingMangaDexId) {
        matchedManga = m;
        break;
      }
      if (url != null && url.isNotEmpty) {
        try {
          final String host = Uri.parse(url).host.toLowerCase();
          if (m.sourceUrls.any((s) => s.toLowerCase().contains(host) && normalizeTitle(s).contains(normIncoming))) {
            matchedManga = m;
            break;
          }
        } catch (_) {}
      }

      final String normLocal = normalizeTitle(m.title);
      if (normLocal == normIncoming || normLocal.contains(normIncoming) || normIncoming.contains(normLocal)) {
        matchedManga = m;
        break;
      }

      if (m.altTitles.any((alt) {
        final String normAlt = normalizeTitle(alt);
        return normAlt == normIncoming || normAlt.contains(normIncoming) || normIncoming.contains(normAlt);
      })) {
        matchedManga = m;
        break;
      }
    }

    // 2. Search MangaDex & AniList in background
    if (matchedManga == null) {
      try {
        final results = await MangaDexService.searchManga(formattedTitle);
        if (results.isNotEmpty) {
          final bestMatch = results.first;
          final String normOfficial = normalizeTitle(bestMatch.title);

          for (final Manga m in collection.mangas) {
            if (m.mangadexId == bestMatch.id) {
              matchedManga = m;
              break;
            }
            final String normLocal = normalizeTitle(m.title);
            if (normLocal == normOfficial || normLocal.contains(normOfficial) || normOfficial.contains(normLocal)) {
              matchedManga = m;
              m.updateMangaDexId(bestMatch.id);
              m.updateAltTitles(bestMatch.altTitles);
              break;
            }
            if (m.altTitles.any((alt) {
              final String normAlt = normalizeTitle(alt);
              return normAlt == normOfficial || normAlt.contains(normOfficial) || normOfficial.contains(normAlt);
            })) {
              matchedManga = m;
              m.updateMangaDexId(bestMatch.id);
              m.updateAltTitles(bestMatch.altTitles);
              break;
            }
          }
        }
      } catch (_) {}
    }

    if (matchedManga == null) {
      try {
        final aniResults = await AniListService.searchManga(formattedTitle);
        if (aniResults.isNotEmpty) {
          final bestAni = aniResults.first;
          final String normAni = normalizeTitle(bestAni.title);

          for (final Manga m in collection.mangas) {
            if (m.anilistId == bestAni.id) {
              matchedManga = m;
              break;
            }
            final String normLocal = normalizeTitle(m.title);
            if (normLocal == normAni || normLocal.contains(normAni) || normAni.contains(normLocal)) {
              matchedManga = m;
              m.updateAniListId(bestAni.id);
              m.updateAltTitles([...m.altTitles, ...bestAni.altTitles]);
              break;
            }
          }
        }
      } catch (_) {}
    }

    // 3. Handle Chapter Update vs Suggestion
    if (matchedManga != null) {
      if (url != null) matchedManga.addSourceUrl(url);

      if (isChapter) {
        if (chapter > matchedManga.currentChapter) {
          matchedManga.updateChapter(chapter);
          if (matchedManga.status == MangaStatus.planToRead) {
            matchedManga.updateStatus(MangaStatus.reading);
          }
          final String msg = "Updated '${matchedManga.displayTitle}' to Chapter $chapter";
          _lastNotificationMessage = msg;
          _addLog("Chapter Updated", msg);
          NotificationService.showChapterUpdatedNotification(
            title: matchedManga.displayTitle,
            chapter: chapter,
          );
        } else {
          final String msg = "'${matchedManga.displayTitle}' is already at Chapter ${matchedManga.currentChapter}";
          _lastNotificationMessage = msg;
          _addLog("Already Up to Date", msg);
          NotificationService.showAlreadyUpToDateNotification(
            title: matchedManga.displayTitle,
            chapter: matchedManga.currentChapter,
          );
        }
      } else {
        final String msg = "'${matchedManga.displayTitle}' is already in your library";
        _lastNotificationMessage = msg;
        _addLog("Already in Library", msg);
        NotificationService.showAlreadyUpToDateNotification(
          title: matchedManga.displayTitle,
          chapter: matchedManga.currentChapter,
        );
      }
      notifyListeners();
    } else {
      final MangaStatus initialStatus = isChapter ? MangaStatus.reading : MangaStatus.planToRead;

      final int existingIndex = _pendingQueue.indexWhere((p) => normalizeTitle(p.rawTitle) == normIncoming);
      if (existingIndex >= 0) {
        _pendingQueue[existingIndex].chapter = chapter;
      } else {
        final pending = PendingMangaUpdate(
          rawTitle: rawTitle,
          formattedTitle: formattedTitle,
          chapter: chapter,
          isChapter: isChapter,
          defaultStatus: initialStatus,
          url: url,
        );
        _pendingQueue.add(pending);
        _fetchPendingCoverAndEnglishTitle(pending);
      }

      _addLog("New Suggestion", "Detected '$formattedTitle' (${isChapter ? 'Ch. $chapter' : 'Title Page'})");
      notifyListeners();

      if (isChapter) {
        NotificationService.showMangaSuggestionNotification(
          title: formattedTitle,
          chapter: chapter,
        );
      } else {
        NotificationService.showMangaSuggestionNotification(
          title: "$formattedTitle (Plan to Read)",
          chapter: 1,
        );
      }
    }
  }

  Future<void> _fetchPendingCoverAndEnglishTitle(PendingMangaUpdate pending) async {
    try {
      final results = await MangaDexService.searchManga(pending.formattedTitle);
      if (results.isNotEmpty) {
        final bestMatch = results.first;
        if (bestMatch.title.isNotEmpty && bestMatch.title != 'Untitled') {
          pending.formattedTitle = bestMatch.title;
        }
        pending.coverUrl = bestMatch.coverUrl;
        notifyListeners();
      } else {
        final aniResults = await AniListService.searchManga(pending.formattedTitle);
        if (aniResults.isNotEmpty) {
          final bestAni = aniResults.first;
          if (bestAni.title.isNotEmpty) {
            pending.formattedTitle = bestAni.title;
          }
          pending.coverUrl = bestAni.coverUrl;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> linkCurrentPendingToExisting(Manga targetManga) async {
    if (_pendingQueue.isEmpty) return;

    final PendingMangaUpdate pending = _pendingQueue.removeAt(0);
    notifyListeners();

    if (pending.isChapter && pending.chapter > targetManga.currentChapter) {
      targetManga.updateChapter(pending.chapter);
      if (targetManga.status == MangaStatus.planToRead) {
        targetManga.updateStatus(MangaStatus.reading);
      }
    }

    if (pending.url != null) {
      targetManga.addSourceUrl(pending.url);
    }

    if (!targetManga.isMangaDexLinked) {
      try {
        final results = await MangaDexService.searchManga(targetManga.title);
        if (results.isNotEmpty) {
          final bestMatch = results.first;
          targetManga.updateMangaDexId(bestMatch.id);
          targetManga.updateAltTitles([...targetManga.altTitles, ...bestMatch.altTitles]);
        }
      } catch (_) {}
    }

    final String msg = "Linked '${pending.formattedTitle}' to '${targetManga.displayTitle}'!";
    _lastNotificationMessage = msg;
    _addLog("Linked Manga", msg);
    notifyListeners();
  }

  Future<void> addCurrentPendingManga(MangaCollectionData collection) async {
    if (_pendingQueue.isEmpty) return;

    final PendingMangaUpdate pending = _pendingQueue.removeAt(0);
    notifyListeners();

    String? coverUrl = pending.coverUrl;
    String synopsis = "";
    List<String> tags = <String>["Manga"];
    String? mangadexId;
    int? anilistId;
    List<String> altTitlesList = <String>[];

    try {
      final results = await MangaDexService.searchManga(pending.formattedTitle);
      if (results.isNotEmpty) {
        final bestMatch = results.first;
        mangadexId = bestMatch.id;
        coverUrl = await MangaDexService.downloadCoverImageLocally(bestMatch.coverUrl);
        synopsis = bestMatch.synopsis;
        tags = List<String>.from(bestMatch.tags);
        if (!tags.contains("MangaDex")) tags.add("MangaDex");
        altTitlesList = List<String>.from(bestMatch.altTitles);
      } else {
        final aniResults = await AniListService.searchManga(pending.formattedTitle);
        if (aniResults.isNotEmpty) {
          final bestAni = aniResults.first;
          anilistId = bestAni.id;
          coverUrl = await AniListService.downloadCoverImageLocally(bestAni.coverUrl);
          synopsis = bestAni.synopsis;
          tags = List<String>.from(bestAni.tags);
          if (!tags.contains("AniList")) tags.add("AniList");
          altTitlesList = List<String>.from(bestAni.altTitles);
        }
      }
    } catch (_) {}

    final Manga newManga = Manga(
      title: pending.formattedTitle,
      currentChapter: pending.chapter,
      imagePath: coverUrl,
      synopsis: synopsis,
      themes: tags,
      rating: 0,
      status: pending.defaultStatus,
      mangadexId: mangadexId,
      anilistId: anilistId,
      altTitles: altTitlesList,
      sourceUrls: pending.url != null ? <String>[pending.url!] : <String>[],
    );

    collection.addManga(newManga);
    final String msg = "Added '${newManga.displayTitle}' (${pending.defaultStatus.label}) to library!";
    _lastNotificationMessage = msg;
    _addLog("Manga Added", msg);
    notifyListeners();
  }

  Future<void> quickAddPendingManga(MangaCollectionData collection) async {
    await addCurrentPendingManga(collection);
  }
}
