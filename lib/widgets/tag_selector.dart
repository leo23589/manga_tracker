import 'package:flutter/material.dart';
import '../core/constants.dart';

class TagSelector extends StatefulWidget {
  final List<String> selectedTags;
  final Function(List<String>) onSelectionChanged;
  final bool enabled;

  const TagSelector({
    super.key,
    required this.selectedTags,
    required this.onSelectionChanged,
    this.enabled = true,
  });

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  Widget _buildSection(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
        ),
        Wrap(
          spacing: 6.0,
          runSpacing: 6.0,
          children: options.map<Widget>((String tag) {
            final bool isSelected = widget.selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: widget.enabled
                  ? (bool selected) {
                      final List<String> newTags = List<String>.from(widget.selectedTags);
                      if (selected) {
                        newTags.add(tag);
                      } else {
                        newTags.remove(tag);
                      }
                      widget.onSelectionChanged(newTags);
                    }
                  : null,
              backgroundColor: const Color(0xFF2A2A2A),
              selectedColor: Colors.indigo,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Colors.indigo : Colors.grey.shade800),
              ),
            );
          }).toList(),
        ),
        const Divider(color: Colors.grey),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildSection("Content", AppConstants.content),
        _buildSection("Themes", AppConstants.themes),
        _buildSection("Genres", AppConstants.genres),
      ],
    );
  }
}

class DisplayTagList extends StatelessWidget {
  final List<String> tags;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? contentTagColor;
  final Color? themeTagColor;
  final Color? genreTagColor;

  const DisplayTagList({
    super.key,
    required this.tags,
    this.backgroundColor,
    this.textColor,
    this.contentTagColor,
    this.themeTagColor,
    this.genreTagColor,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 6.0,
      runSpacing: 6.0,
      children: tags.map<Widget>((String tag) {
        Color? effectiveBackgroundColor = backgroundColor ?? Colors.grey.shade800;
        Color? effectiveTextColor = textColor ?? Colors.white70;
        Widget? avatar;

        if (tag == "MangaDex" || tag == "Linked") {
          effectiveBackgroundColor = const Color(0xFF4F46E5);
          effectiveTextColor = Colors.white;
          avatar = const Text("🐱", style: TextStyle(fontSize: 12));
        } else if (tag == "AniList") {
          effectiveBackgroundColor = const Color(0xFF0284C7);
          effectiveTextColor = Colors.white;
          avatar = const Text("🌸", style: TextStyle(fontSize: 12));
        } else if (tag == "Manhwa") {
          effectiveBackgroundColor = const Color(0xFFD97706); // Vibrant Amber/Orange for Manhwa
          effectiveTextColor = Colors.white;
        } else if (AppConstants.content.contains(tag)) {
          effectiveBackgroundColor = contentTagColor ?? Colors.red.shade900;
        } else if (AppConstants.themes.contains(tag)) {
          effectiveBackgroundColor = themeTagColor ?? Colors.deepPurple.shade900;
        } else if (AppConstants.genres.contains(tag)) {
          effectiveBackgroundColor = genreTagColor ?? Colors.blue.shade900;
        }

        final bool isSpecialTag = tag == "MangaDex" || tag == "AniList" || tag == "Linked";

        return Chip(
          avatar: avatar,
          label: Text(tag),
          backgroundColor: effectiveBackgroundColor,
          labelStyle: TextStyle(
            color: effectiveTextColor,
            fontSize: 12,
            fontWeight: isSpecialTag || tag == "Manhwa" ? FontWeight.bold : FontWeight.normal,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: tag == "MangaDex" || tag == "Linked"
                  ? const Color(0xFF818CF8)
                  : (tag == "AniList"
                      ? const Color(0xFF38BDF8)
                      : (tag == "Manhwa" ? const Color(0xFFFBBF24) : Colors.grey.shade700)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
