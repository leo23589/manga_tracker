import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/manga.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MangaCollectionData mangaCollection = context.watch<MangaCollectionData>();
    final List<Manga> mangas = mangaCollection.mangas;

    final int totalMangas = mangas.length;
    final int totalChapters = mangas.fold<int>(0, (int sum, Manga item) => sum + item.currentChapter);

    final int mangaCount = mangas.where((Manga manga) => manga.themes.contains("Manga")).length;
    final int manhwaCount = mangas.where((Manga manga) => manga.themes.contains("Manhwa")).length;

    final Map<String, int> tagCounts = <String, int>{};
    for (Manga m in mangas) {
      for (String t in m.themes) {
        tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
    }
    final List<MapEntry<String, int>> sortedTags = tagCounts.entries.toList()..sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value.compareTo(a.value));
    final List<MapEntry<String, int>> topTags = sortedTags.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: _StatCard(title: "Titles read", value: "$totalMangas", icon: Icons.book, color: Colors.blue)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(title: "Chapters read", value: "$totalChapters", icon: Icons.library_books, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(child: _StatCard(title: "Mangas", value: "$mangaCount", icon: Icons.menu_book, color: Colors.purple)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(title: "Manhwas", value: "$manhwaCount", icon: Icons.auto_stories, color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 30),
            const Text("Favorite Genres", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            if (topTags.isEmpty)
              const Text("Add themes to your mangas to see stats!")
            else
              ...topTags.map<Widget>((MapEntry<String, int> entry) {
                final double percent = entry.value / (topTags.first.value == 0 ? 1 : topTags.first.value);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("${entry.value} mangas"),
                        ],
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: percent,
                        backgroundColor: Colors.grey.shade800,
                        color: Colors.indigoAccent,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      )
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
