import '../core/constants.dart';

class MangaUtils {
  static bool looksLikeEnglishTitle(String text) {
    if (text.isEmpty) return false;
    final RegExp englishWords = RegExp(
      r'\b(the|a|an|leveling|solo|return|hero|tower|player|rank|system|god|lord|king|princess|queen|demon|magic|sword|reincarnation|villain|extra|guide|strategy|conquer|hunter|necromancer|archmage|academy|saint|dungeon|master|heavenly|dragon|star|shadow|blade|realm|emperor|legend|infinite|regressor|transmigrated)\b',
      caseSensitive: false,
    );
    return englishWords.hasMatch(text);
  }

  static List<String> deduplicateStrings(List<String> list, String primary) {
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

  static String getBaseUrl(String url) {
    if (url.isEmpty) return "";
    String clean = url.trim().toLowerCase().split('?').first.split('#').first;
    
    clean = clean.replaceFirst(RegExp(r'^(https?://)www\.'), r'$1');
    clean = clean.replaceAll(RegExp(r'[-_/](?:chapter|chap|ch|c)[-_=]?[0-9]+(?:\.[0-9]+)?.*$', caseSensitive: false), '');
    
    if (clean.endsWith('/')) clean = clean.substring(0, clean.length - 1);
    return clean;
  }

  static List<String> deduplicateUrls(List<String> urls) {
    final Map<String, String> hostToUrl = <String, String>{};
    for (final String url in urls) {
      if (url.trim().isEmpty) continue;
      try {
        final String baseTemplate = getBaseUrl(url);
        final Uri uri = Uri.parse(baseTemplate);
        final String host = uri.host;
        hostToUrl[host] = baseTemplate;
      } catch (_) {}
    }
    return hostToUrl.values.toList();
  }

  static List<String> sortTags(List<String> tagsInput, String? mId, int? aId) {
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
}
