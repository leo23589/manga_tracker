import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/manga.dart';
import 'mangadex_service.dart';
import 'notification_service.dart';

class PendingMangaUpdate {
  final String rawTitle;
  final String formattedTitle;
  final int chapter;
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

  PendingMangaUpdate? _pendingManga;
  String? _lastNotificationMessage;

  bool get isListening => _isListening;
  int get port => _port;
  PendingMangaUpdate? get pendingManga => _pendingManga;
  String? get lastNotificationMessage => _lastNotificationMessage;

  void clearPendingManga() {
    _pendingManga = null;
    notifyListeners();
  }

  void clearNotificationMessage() {
    _lastNotificationMessage = null;
    notifyListeners();
  }

  Future<void> startServer(MangaCollectionData collection) async {
    if (_isListening) return;

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
      _isListening = true;
      notifyListeners();
      debugPrint("ExtensionServerService running on http://127.0.0.1:$_port");

      _server!.listen((HttpRequest request) async {
        // Enable CORS
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
  }) {
    final String normIncoming = normalizeTitle(rawTitle);
    final String formattedTitle = formatTitleFromSlug(rawTitle);

    Manga? matchedManga;
    for (final Manga m in collection.mangas) {
      final String normLocal = normalizeTitle(m.title);
      if (normLocal == normIncoming || normLocal.contains(normIncoming) || normIncoming.contains(normLocal)) {
        matchedManga = m;
        break;
      }
    }

    if (matchedManga != null) {
      if (isChapter) {
        if (chapter > matchedManga.currentChapter) {
          matchedManga.updateChapter(chapter);
          if (matchedManga.status == MangaStatus.planToRead) {
            matchedManga.updateStatus(MangaStatus.reading);
          }
          _lastNotificationMessage = "Updated '${matchedManga.title}' to Chapter $chapter";
          NotificationService.showChapterUpdatedNotification(
            title: matchedManga.title,
            chapter: chapter,
          );
        } else {
          _lastNotificationMessage = "'${matchedManga.title}' is already at Chapter ${matchedManga.currentChapter}";
        }
      } else {
        _lastNotificationMessage = "'${matchedManga.title}' is already in your library";
      }
      _pendingManga = null;
      notifyListeners();
    } else {
      final MangaStatus initialStatus = isChapter ? MangaStatus.reading : MangaStatus.planToRead;

      _pendingManga = PendingMangaUpdate(
        rawTitle: rawTitle,
        formattedTitle: formattedTitle,
        chapter: chapter,
        isChapter: isChapter,
        defaultStatus: initialStatus,
        url: url,
      );
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

      _fetchPendingCoverAndEnglishTitle(formattedTitle);
    }
  }

  Future<void> _fetchPendingCoverAndEnglishTitle(String query) async {
    try {
      final results = await MangaDexService.searchManga(query);
      if (results.isNotEmpty && _pendingManga != null) {
        final bestMatch = results.first;
        final String officialEnglishTitle = (bestMatch.title.isNotEmpty && bestMatch.title != 'Untitled')
            ? bestMatch.title
            : _pendingManga!.formattedTitle;

        _pendingManga = PendingMangaUpdate(
          rawTitle: _pendingManga!.rawTitle,
          formattedTitle: officialEnglishTitle,
          chapter: _pendingManga!.chapter,
          isChapter: _pendingManga!.isChapter,
          defaultStatus: _pendingManga!.defaultStatus,
          url: _pendingManga!.url,
          coverUrl: bestMatch.coverUrl,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> quickAddPendingManga(MangaCollectionData collection) async {
    if (_pendingManga == null) return;

    final PendingMangaUpdate pending = _pendingManga!;

    String? coverUrl = pending.coverUrl;
    String synopsis = "";
    List<String> tags = <String>["Manga"];

    try {
      final results = await MangaDexService.searchManga(pending.formattedTitle);
      if (results.isNotEmpty) {
        final bestMatch = results.first;
        coverUrl = await MangaDexService.downloadCoverImageLocally(bestMatch.coverUrl);
        synopsis = bestMatch.synopsis;
        tags = bestMatch.tags;
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
    );

    collection.addManga(newManga);
    _lastNotificationMessage = "Added '${pending.formattedTitle}' (${pending.defaultStatus.label}) to your library!";
    _pendingManga = null;
    notifyListeners();
  }
}
