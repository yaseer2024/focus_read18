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
    _load();
  }

  Future<void> _load() async {
    final data = await FreeBooksService.fetchBooks();
    setState(() {
      serverBooks = data;
      loading = false;
    });
  }

  Future<void> openBook(Map<String, dynamic> data) async {
    // ⬇️ Download
    final Book downloaded = await FreeBooksService.downloadBook(data);

    // 💾 Save or update in storage
    final books = await BookStorage.load();
    final index = books.indexWhere((b) => b.id == downloaded.id);

    if (index == -1) {
      books.add(downloaded);
    }

    await BookStorage.save(books);

    // 🔄 RELOAD updated book before opening
    final refreshedBooks = await BookStorage.load();
    final book = refreshedBooks.firstWhere((b) => b.id == downloaded.id);

    // 📖 Open
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfScreen(book: book),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Free Books')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: serverBooks.length,
        itemBuilder: (_, i) {
          final b = serverBooks[i];
          return ListTile(
            leading: const Icon(Icons.cloud_download),
            title: Text(b['title']),
            onTap: () => openBook(b),
          );
        },
      ),
    );
  }
}
