import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:raunaq/catering_screen.dart';
import 'package:raunaq/decoration_screen.dart';
import 'package:raunaq/music_screen.dart';
import 'package:raunaq/photography_screen.dart';
import 'package:raunaq/venues_screen.dart';

/// Lists every item under `categories/{venues|catering|photography|decoration|music}/items`
/// with a top search bar (client-side filter).
class ExploreAllScreen extends StatefulWidget {
  const ExploreAllScreen({super.key});

  @override
  State<ExploreAllScreen> createState() => _ExploreAllScreenState();
}

class _ExploreAllScreenState extends State<ExploreAllScreen> {
  static const _primaryColor = Color(0xFF00A2FF);

  static const List<String> _categoryIds = [
    'venues',
    'catering',
    'photography',
    'decoration',
    'music',
  ];

  static const Map<String, String> _categoryLabels = {
    'venues': 'Venues',
    'catering': 'Catering',
    'photography': 'Photography',
    'decoration': 'Decoration',
    'music': 'Music',
  };

  final _searchController = TextEditingController();
  final List<_ExploreRow> _all = [];
  List<_ExploreRow> _visible = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = <_ExploreRow>[];
      final fs = FirebaseFirestore.instance;
      for (final cat in _categoryIds) {
        final snap =
            await fs.collection('categories').doc(cat).collection('items').get();
        for (final doc in snap.docs) {
          rows.add(_ExploreRow(
            categoryId: cat,
            docId: doc.id,
            data: doc.data(),
          ));
        }
      }
      rows.sort((a, b) {
        final na = a.displayName.toLowerCase();
        final nb = b.displayName.toLowerCase();
        final c = na.compareTo(nb);
        if (c != 0) return c;
        return a.categoryId.compareTo(b.categoryId);
      });
      if (!mounted) return;
      setState(() {
        _all
          ..clear()
          ..addAll(rows);
        _visible = List<_ExploreRow>.from(_all);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _applySearch(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _visible = List<_ExploreRow>.from(_all));
      return;
    }
    setState(() {
      _visible = _all.where((row) {
        if (row.displayName.toLowerCase().contains(query)) return true;
        final label = _categoryLabels[row.categoryId] ?? row.categoryId;
        if (label.toLowerCase().contains(query)) return true;
        final extra = row.searchExtra.toLowerCase();
        if (extra.contains(query)) return true;
        return false;
      }).toList();
    });
  }

  void _openCategory(BuildContext context, String categoryId) {
    final Widget page;
    switch (categoryId) {
      case 'venues':
        page = const VenuesScreen();
        break;
      case 'catering':
        page = const CateringScreen();
        break;
      case 'photography':
        page = const PhotographyScreen();
        break;
      case 'decoration':
        page = const DecorationScreen();
        break;
      case 'music':
        page = const MusicScreen();
        break;
      default:
        return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
        title: const Text(
          'Explore',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _applySearch,
              decoration: InputDecoration(
                hintText: 'Search all categories…',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 22),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              _loading
                  ? 'Loading…'
                  : '${_visible.length} item${_visible.length == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _primaryColor))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: _primaryColor,
                        onRefresh: _load,
                        child: _visible.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 80),
                                  Center(
                                    child: Text(
                                      'No items match your search.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: _visible.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final row = _visible[i];
                                  final label =
                                      _categoryLabels[row.categoryId] ??
                                          row.categoryId;
                                  return Material(
                                    color: const Color(0xFFFAFBFD),
                                    borderRadius: BorderRadius.circular(12),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      leading: Text(
                                        row.emoji,
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                      title: Text(
                                        row.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        row.subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                        ),
                                      ),
                                      trailing: Chip(
                                        label: Text(
                                          label,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor:
                                            _primaryColor.withValues(alpha: 0.12),
                                        side: BorderSide.none,
                                      ),
                                      onTap: () =>
                                          _openCategory(context, row.categoryId),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ExploreRow {
  _ExploreRow({
    required this.categoryId,
    required this.docId,
    required this.data,
  });

  final String categoryId;
  final String docId;
  final Map<String, dynamic> data;

  String get displayName {
    final n = data['name'];
    if (n != null && '$n'.trim().isNotEmpty) return '$n'.trim();
    return 'Untitled';
  }

  String get emoji => (data['emoji'] as String?) ?? '📌';

  /// Extra text used for search (location, genre, etc.).
  String get searchExtra {
    final parts = <String>[];
    void add(dynamic v) {
      if (v != null && '$v'.trim().isNotEmpty) parts.add('$v');
    }

    add(data['location']);
    add(data['genre']);
    add(data['specialty']);
    add(data['type']);
    add(data['theme']);
    add(data['price']);
    return parts.join(' ');
  }

  String get subtitle {
    final parts = <String>[];
    void add(dynamic v) {
      if (v != null && '$v'.trim().isNotEmpty) parts.add('$v');
    }

    switch (categoryId) {
      case 'venues':
        add(data['location']);
        add(data['price']);
        break;
      case 'catering':
        add(data['specialty']);
        add(data['price']);
        break;
      case 'photography':
        add(data['type']);
        add(data['price']);
        break;
      case 'decoration':
        add(data['theme']);
        add(data['price']);
        break;
      case 'music':
        add(data['genre']);
        add(data['price']);
        break;
      default:
        add(data['price']);
    }
    return parts.isEmpty ? '' : parts.take(3).join(' · ');
  }
}
