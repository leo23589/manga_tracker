import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../services/extension_server_service.dart';
import '../widgets/dialogs/add_manga_dialog.dart';
import '../widgets/manga_widgets.dart';

class MangaListPage extends StatefulWidget {
  const MangaListPage({super.key});

  @override
  State<MangaListPage> createState() => _MangaListPageState();
}

class _MangaListPageState extends State<MangaListPage> {
  final TextEditingController _searchController = TextEditingController();
  MangaStatus? _statusFilter;
  bool? _linkedFilter; // null = all, true = linked, false = not linked

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showActivityLogsSheet(BuildContext context, ExtensionServerService serverService) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            final logs = serverService.logs;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notifications_active, color: Colors.amberAccent),
                          SizedBox(width: 8),
                          Text("Activity Logs 🔔", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (logs.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            serverService.clearLogs();
                            Navigator.pop(modalContext);
                          },
                          icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.redAccent),
                          label: const Text("Clear All", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ),
                    ],
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Logs are automatically cleared after 30 days.", style: TextStyle(fontSize: 11, color: Colors.white54)),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: logs.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off_outlined, size: 48, color: Colors.white30),
                                SizedBox(height: 12),
                                Text("No recent activity logs.", style: TextStyle(color: Colors.white54)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: logs.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                            itemBuilder: (context, index) {
                              final entry = logs[index];
                              final timeAgo = _formatTimestamp(entry.timestamp);

                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: const Color(0xFF6366F1).withAlpha((255 * 0.2).round()),
                                  child: const Icon(Icons.sync, size: 16, color: Color(0xFF818CF8)),
                                ),
                                title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text(entry.message, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                trailing: Text(timeAgo, style: const TextStyle(fontSize: 10, color: Colors.white38)),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  @override
  Widget build(BuildContext context) {
    final MangaCollectionData mangaCollection = context.watch<MangaCollectionData>();
    final ExtensionServerService serverService = context.watch<ExtensionServerService>();

    final List<Manga> filteredList = mangaCollection.mangas.where((manga) {
      final query = _searchController.text.toLowerCase();
      final matchesSearch = query.isEmpty ||
          manga.title.toLowerCase().contains(query) ||
          manga.altTitles.any((alt) => alt.toLowerCase().contains(query));
      final matchesStatus = _statusFilter == null || manga.status == _statusFilter;
      final matchesLink = _linkedFilter == null ||
          (_linkedFilter == true && manga.isLinked) ||
          (_linkedFilter == false && !manga.isLinked);
      return matchesSearch && matchesStatus && matchesLink;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Library 📚"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: serverService.logs.isNotEmpty,
              backgroundColor: Colors.amber,
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: "Activity Logs",
            onPressed: () => _showActivityLogsSheet(context, serverService),
          ),
          PopupMenuButton<MangaSortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (MangaSortOption option) {
              mangaCollection.sortOption = option;
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<MangaSortOption>>[
              const PopupMenuItem<MangaSortOption>(
                value: MangaSortOption.lastAdded,
                child: Row(children: [Icon(Icons.more_time, size: 20), SizedBox(width: 8), Text('Recently Added')]),
              ),
              const PopupMenuItem<MangaSortOption>(
                value: MangaSortOption.lastUpdated,
                child: Row(children: [Icon(Icons.update, size: 20), SizedBox(width: 8), Text('Recently Updated')]),
              ),
              const PopupMenuItem<MangaSortOption>(
                value: MangaSortOption.rating,
                child: Row(children: [Icon(Icons.star, size: 20), SizedBox(width: 8), Text('Highest Rated')]),
              ),
              const PopupMenuItem<MangaSortOption>(
                value: MangaSortOption.title,
                child: Row(children: [Icon(Icons.sort_by_alpha, size: 20), SizedBox(width: 8), Text('Alphabetical')]),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddMangaDialog(
          context: context,
          mangaCollection: mangaCollection,
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Home Page Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Quick search library or alt titles...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFF1E1E28),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Quick Filter Chips (Status & Linked)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text("All"),
                  selected: _statusFilter == null && _linkedFilter == null,
                  onSelected: (_) => setState(() {
                    _statusFilter = null;
                    _linkedFilter = null;
                  }),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.link, size: 14, color: Colors.amberAccent),
                  label: const Text("Linked 🔗"),
                  selected: _linkedFilter == true,
                  selectedColor: const Color(0xFF4F46E5),
                  onSelected: (selected) {
                    setState(() {
                      _linkedFilter = selected ? true : null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.link_off, size: 14, color: Colors.white70),
                  label: const Text("Not Linked 📍"),
                  selected: _linkedFilter == false,
                  selectedColor: Colors.grey.shade800,
                  onSelected: (selected) {
                    setState(() {
                      _linkedFilter = selected ? false : null;
                    });
                  },
                ),
                const SizedBox(width: 12),
                const SizedBox(
                  height: 20,
                  child: VerticalDivider(color: Colors.white24, width: 1),
                ),
                const SizedBox(width: 12),
                ...MangaStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(status.label),
                      selected: _statusFilter == status,
                      onSelected: (selected) {
                        setState(() {
                          _statusFilter = selected ? status : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isNotEmpty || _statusFilter != null || _linkedFilter != null
                          ? "No mangas match your filters."
                          : "No mangas found in your library.",
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredList.length,
                    padding: const EdgeInsets.all(10),
                    itemBuilder: (BuildContext context, int index) {
                      return MangaListTile(
                        key: ValueKey(filteredList[index].title + filteredList[index].createdAt.toString()),
                        manga: filteredList[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
