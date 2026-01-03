import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/free_books_service.dart';
import '../storage/book_storage.dart';
import 'pdf_screen.dart';

class FreeBooksScreen extends StatefulWidget {
  const FreeBooksScreen({super.key});

  @override
  State<FreeBooksScreen> createState() => _FreeBooksScreenState();
}

class _FreeBooksScreenState extends State<FreeBooksScreen> {
  List<Map<String, dynamic>> serverBooks = [];
  Set<String> downloadedIds = {};
  String? loadingBookId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  /// 📡 Load books + local downloaded state
  Future<void> _loadBooks() async {
    try {
      final data = await FreeBooksService.fetchBooks();
      final localBooks = await BookStorage.load();

      if (!mounted) return;

      setState(() {
        serverBooks = data;
        downloadedIds = localBooks.map((b) => b.id).toSet();
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  /// ⬇️ Download → save → open (with UI feedback)
  Future<void> _openBook(Map<String, dynamic> data) async {
    final id = data['id'];

    setState(() => loadingBookId = id);

    try {
      final Book downloaded = await FreeBooksService.downloadBook(data);

      final books = await BookStorage.load();
      final exists = books.any((b) => b.id == downloaded.id);

      if (!exists) {
        books.add(downloaded);
        await BookStorage.save(books);
      }

      final freshBooks = await BookStorage.load();
      final book =
      freshBooks.firstWhere((b) => b.id == downloaded.id);

      if (!mounted) return;

      setState(() {
        downloadedIds.add(downloaded.id);
        loadingBookId = null;
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfScreen(book: book),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => loadingBookId = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open book')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Free Books'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : serverBooks.isEmpty
          ? const Center(
        child: Text(
          'No free books available',
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.separated(
        itemCount: serverBooks.length,
        separatorBuilder: (_, __) =>
        const Divider(height: 1),
        itemBuilder: (_, i) {
          final book = serverBooks[i];
          final id = book['id'];
          final isDownloaded = downloadedIds.contains(id);
          final isLoading = loadingBookId == id;

          return _AnimatedFreeBookTile(
            title: book['title'] ?? 'Untitled',
            isDownloaded: isDownloaded,
            isLoading: isLoading,
            onTap: () => _openBook(book),
          );
        },
      ),
    );
  }
}

/// ===============================
/// 🎯 Animated Free Book Tile
/// ===============================
class _AnimatedFreeBookTile extends StatefulWidget {
  final String title;
  final bool isDownloaded;
  final bool isLoading;
  final VoidCallback onTap;

  const _AnimatedFreeBookTile({
    required this.title,
    required this.isDownloaded,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_AnimatedFreeBookTile> createState() =>
      _AnimatedFreeBookTileState();
}

class _AnimatedFreeBookTileState
    extends State<_AnimatedFreeBookTile> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) => setState(() => pressed = false),
      onTapCancel: () => setState(() => pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: ListTile(
          leading: widget.isDownloaded
              ? const Icon(Icons.check_circle,
              color: Colors.green)
              : const Icon(Icons.cloud_download_outlined),
          title: Text(widget.title),
          subtitle: widget.isDownloaded
              ? const Text(
            'Downloaded',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          )
              : null,
          trailing: widget.isLoading
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
