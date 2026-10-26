import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/manga.dart';
import 'pages/manga_list_page.dart';
import 'pages/search_page.dart';
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
              shadowColor: Colors.black.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF161620),
              foregroundColor: Color(0xFFF3F4F6),
              elevation: 0,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(0xFF14141D),
              indicatorColor: const Color(0xFF6366F1).withOpacity(0.3),
              labelTextStyle: WidgetStateProperty.all(
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white70),
              ),
            ),
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
              backgroundColor: const Color(0xFF6366F1),
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
                elevation: 12,
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF1E1B4B),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5), width: 1.5),
                  ),
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      if (pending.coverUrl != null && pending.coverUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: MangaCoverImage(
                            imagePath: pending.coverUrl,
                            width: 45,
                            height: 65,
                            borderRadius: 8,
                          ),
                        )
                      else
                        Container(
                          width: 45,
                          height: 65,
                          margin: const EdgeInsets.only(right: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade900.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.extension, color: Colors.amber, size: 28),
                        ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Extension Detected Reading",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amberAccent),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${pending.formattedTitle} (Ch. ${pending.chapter})",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
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
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onPressed: () {
                          serverService.quickAddPendingManga(collection);
                        },
                        child: const Text("Quick Add", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.white70),
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
