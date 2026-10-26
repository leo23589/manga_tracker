import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/manga.dart';
import 'pages/manga_list_page.dart';
import 'pages/search_page.dart';
import 'pages/stats_page.dart';
import 'services/extension_server_service.dart';

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
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const MainScreen(),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final collection = context.read<MangaCollectionData>();
      final serverService = context.read<ExtensionServerService>();
      serverService.startServer(collection);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
              backgroundColor: Colors.indigo,
            ),
          );
          serverService.clearNotificationMessage();
        }
      });
    }

    final pending = serverService.pendingManga;

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
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: Colors.indigo.shade900,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.extension, color: Colors.amber, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Extension Detected Reading",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                            ),
                            Text(
                              "${pending.formattedTitle} (Ch. ${pending.chapter})",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              "Not in your library yet",
                              style: TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onPressed: () {
                          serverService.quickAddPendingManga(collection);
                        },
                        child: const Text("Quick Add", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          serverService.clearPendingManga();
                        },
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
