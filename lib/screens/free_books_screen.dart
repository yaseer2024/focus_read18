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

  /// ⬇️ Download → save → open
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
      final book =
      freshBooks.firstWhere((b) => b.id == downloaded.id);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfScreen(book: book),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open book'),
        ),
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

          return ListTile(
            leading:
            const Icon(Icons.cloud_download_outlined),
            title: Text(book['title'] ?? 'Untitled'),
            trailing:
            const Icon(Icons.chevron_right),
            onTap: () => _openBook(book),
          );
        },
      ),
    );
  }
}
