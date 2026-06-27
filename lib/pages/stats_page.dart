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
      
      await Share.shareXFiles([XFile(file.path)], text: 'Ma sauvegarde Manga Tracker');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'exportation : $e')),
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
              content: Text(success ? 'Importation réussie !' : 'Fichier de sauvegarde invalide.'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'importation : $e')),
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
            // Section Sauvegarde
            const Text("Sauvegarde & Restauration", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportData(context, mangaCollection),
                    icon: const Icon(Icons.upload),
                    label: const Text("Exporter"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.withAlpha(50),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _importData(context, mangaCollection),
                    icon: const Icon(Icons.download),
                    label: const Text("Importer"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withAlpha(50),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            const Text("Données Globales", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
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
