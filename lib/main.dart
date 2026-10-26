import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/manga.dart';
import 'pages/manga_list_page.dart';
import 'pages/search_page.dart';
import 'pages/splash_screen.dart';
import 'pages/stats_page.dart';
import 'services/extension_server_service.dart';
import 'widgets/manga_cover_image.dart';

void main() {
  runApp(const MangaApp());
}

class MangaApp extends StatelessWidget {
  const MangaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MangaCollectionData>(
          create: (BuildContext context) => MangaCollectionData(),
        ),
        ChangeNotifierProvider<ExtensionServerService>(
          create: (BuildContext context) => ExtensionServerService(),
        ),
      ],
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.dark,
              surface: const Color(0xFF121218),
              surfaceContainerHighest: const Color(0xFF1E1E28),
              onSurface: const Color(0xFFF3F4F6),
              primary: const Color(0xFF818CF8),
              primaryContainer: const Color(0xFF1E1E2A),
            ),
            scaffoldBackgroundColor: const Color(0xFF0F0F14),
            cardTheme: CardThemeData(
              color: const Color(0xFF1A1A24),
              elevation: 4,
              shadowColor: Colors.black.withAlpha((255 * 0.5).round()),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF161620),
              foregroundColor: Color(0xFFF3F4F6),
              elevation: 0,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(0xFF14141D),
              indicatorColor: const Color(0xFF6366F1).withAlpha((255 * 0.3).round()),
              labelTextStyle: WidgetStateProperty.all(
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white70),
              ),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    MangaListPage(),
    SearchPage(),
    StatsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showLinkToExistingDialog(
    BuildContext parentContext,
    MangaCollectionData collection,
    ExtensionServerService serverService,
    PendingMangaUpdate pending,
  ) {
    if (collection.mangas.isEmpty) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(content: Text("Your library is empty. Add a manga first!")),
      );
      return;
    }

    String searchQuery = "";

    showDialog<void>(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final List<Manga> filtered = collection.mangas.where((m) {
              final q = searchQuery.toLowerCase();
              return q.isEmpty ||
                  m.title.toLowerCase().contains(q) ||
                  m.altTitles.any((alt) => alt.toLowerCase().contains(q));
            }).toList();

            return AlertDialog(
              title: const Text("Link to Existing Manga"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: "Search your library...",
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setState(() => searchQuery = val),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: filtered.isEmpty
                          ? const Center(child: Padding(padding: EdgeInsets.all(16), child: Text("No manga found.")))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final manga = filtered[index];
                                return ListTile(
                                  leading: MangaCoverImage(
                                    imagePath: manga.imagePath,
                                    width: 35,
                                    height: 50,
                                    borderRadius: 6,
                                  ),
                                  title: Text(manga.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text("Ch. ${manga.currentChapter} • ${manga.status.label}", style: const TextStyle(fontSize: 12)),
                                  trailing: const Icon(Icons.link, color: Colors.indigoAccent),
                                  onTap: () {
                                    Navigator.of(dialogContext).pop();
                                    serverService.linkCurrentPendingToExisting(manga);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<MangaCollectionData>();
    final serverService = context.watch<ExtensionServerService>();

    if (serverService.lastNotificationMessage != null) {
      final String message = serverService.lastNotificationMessage!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF6366F1),
            ),
          );
          serverService.clearNotificationMessage();
        }
      });
    }

    final pending = serverService.currentPending;
    final queueCount = serverService.pendingQueue.length;

    return Scaffold(
      body: Stack(
        children: [
          _pages[_selectedIndex],
          if (pending != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Material(
                elevation: 16,
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF181824),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withAlpha((255 * 0.6).round()),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((255 * 0.5).round()),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.extension, color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                pending.isChapter ? "New Manga Detected" : "Add to Plan to Read",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                          if (queueCount > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade900,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "1 of $queueCount in queue",
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          MangaCoverImage(
                            imagePath: pending.coverUrl,
                            width: 50,
                            height: 75,
                            borderRadius: 8,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pending.formattedTitle,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: pending.defaultStatus == MangaStatus.reading
                                            ? const Color(0xFF0284C7).withAlpha((255 * 0.3).round())
                                            : const Color(0xFF7C3AED).withAlpha((255 * 0.3).round()),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        pending.defaultStatus.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: pending.defaultStatus == MangaStatus.reading
                                              ? const Color(0xFF38BDF8)
                                              : const Color(0xFFA78BFA),
                                        ),
                                      ),
                                    ),
                                    if (pending.isChapter) ...[
                                      const SizedBox(width: 10),
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              if (pending.chapter > 1) {
                                                serverService.updateCurrentPendingChapter(pending.chapter - 1);
                                              }
                                            },
                                            child: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.white70),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                            child: Text(
                                              "Ch. ${pending.chapter}",
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              serverService.updateCurrentPendingChapter(pending.chapter + 1);
                                            },
                                            child: const Icon(Icons.add_circle_outline, size: 18, color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF818CF8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            icon: const Icon(Icons.link, size: 16),
                            label: const Text("Link to Existing", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              _showLinkToExistingDialog(context, collection, serverService, pending);
                            },
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  serverService.dismissCurrentPending();
                                },
                                child: const Text("Skip", style: TextStyle(color: Colors.white54, fontSize: 12)),
                              ),
                              const SizedBox(width: 4),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () {
                                  serverService.addCurrentPendingManga(collection);
                                },
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text("Add New", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.library_books),
            label: 'Mangas',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
