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
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  /// 📡 Load books dynamically from server
  Future<void> _loadBooks() async {
    try {
      final data = await FreeBooksService.fetchBooks();
      if (!mounted) return;

      setState(() {
        serverBooks = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  /// ⬇️ Download → save → open (UNCHANGED CORE)
  Future<void> _openBook(Map<String, dynamic> data) async {
    try {
      final Book downloaded = await FreeBooksService.downloadBook(data);

      final books = await BookStorage.load();
      final exists = books.any((b) => b.id == downloaded.id);

      if (!exists) {
        books.add(downloaded);
        await BookStorage.save(books);
      }

      final freshBooks = await BookStorage.load();
      final book = freshBooks.firstWhere((b) => b.id == downloaded.id);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfScreen(book: book),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open book')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text('Free Books'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : serverBooks.isEmpty
          ? _emptyState()
          : Column(
        children: [
          _header(),
          Expanded(child: _booksList()),
        ],
      ),
    );
  }

  /// 🌈 Header section
  Widget _header() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6A5AE0),
            Color(0xFF9D8CFF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Free Books',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Download and read instantly',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// 📚 Book list
  Widget _booksList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: serverBooks.length,
      itemBuilder: (_, i) {
        final book = serverBooks[i];

        return GestureDetector(
          onTap: () => _openBook(book),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFEEEAFE),
                  ),
                  child: const Icon(
                    Icons.cloud_download_outlined,
                    color: Color(0xFF6A5AE0),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    book['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 💤 Empty state
  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No free books available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
