import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/manga.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  Future<void> _exportData(BuildContext context, MangaCollectionData collection) async {
    try {
      final String json = await collection.getExportJson();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/manga_backup.json');
      await file.writeAsString(json);
      
      await Share.shareXFiles([XFile(file.path)], text: 'Manga Tracker Backup');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export Error: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, MangaCollectionData collection) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        bool success = await collection.importData(content);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Import successful!' : 'Invalid backup file.'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final MangaCollectionData mangaCollection = context.watch<MangaCollectionData>();
    final List<Manga> mangas = mangaCollection.mangas;

    final int totalMangas = mangas.length;
    final int totalChapters = mangas.fold<int>(0, (int sum, Manga item) => sum + item.currentChapter);

    final int readingCount = mangas.where((Manga m) => m.status == MangaStatus.reading).length;
    final int finishedCount = mangas.where((Manga m) => m.status == MangaStatus.finished).length;

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
        title: const Text("Statistics & Backup"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Backup Section
            const Text("Backup & Restore", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportData(context, mangaCollection),
                    icon: const Icon(Icons.upload),
                    label: const Text("Export JSON"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1).withAlpha((255 * 0.3).round()),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _importData(context, mangaCollection),
                    icon: const Icon(Icons.download),
                    label: const Text("Import JSON"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981).withAlpha((255 * 0.3).round()),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            
            const Text("Global Statistics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(child: _StatCard(title: "Titles in Library", value: "$totalMangas", icon: Icons.book, color: const Color(0xFF818CF8))),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(title: "Chapters Read", value: "$totalChapters", icon: Icons.library_books, color: const Color(0xFF34D399))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(child: _StatCard(title: "Currently Reading", value: "$readingCount", icon: Icons.auto_stories, color: const Color(0xFF38BDF8))),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(title: "Finished Reading", value: "$finishedCount", icon: Icons.check_circle, color: const Color(0xFF10B981))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(child: _StatCard(title: "Mangas", value: "$mangaCount", icon: Icons.menu_book, color: const Color(0xFFA78BFA))),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(title: "Manhwas", value: "$manhwaCount", icon: Icons.style, color: const Color(0xFFFB923C))),
              ],
            ),
            const SizedBox(height: 28),
            const Text("Favorite Genres & Themes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (topTags.isEmpty)
              const Text("Add genres or themes to your mangas to see stats!")
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
                          Text("${entry.value} mangas", style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: percent,
                        backgroundColor: const Color(0xFF1E1E28),
                        color: const Color(0xFF6366F1),
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
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha((255 * 0.3).round()), width: 1),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
