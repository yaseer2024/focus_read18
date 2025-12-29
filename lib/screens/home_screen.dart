import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';
import '../storage/book_storage.dart';
import '../storage/reading_time_storage.dart';
import 'pdf_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Book> books = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => isLoading = true);
    final loadedBooks = await BookStorage.load();
    setState(() {
      books = loadedBooks;
      isLoading = false;
    });
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;

    final file = File(result.files.single.path!);
    final dir = await getApplicationDocumentsDirectory();

    final cleanName = result.files.single.name
        .replaceAll(' ', '_')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('[', '')
        .replaceAll(']', '');

    final saved = await file.copy('${dir.path}/$cleanName');

    final newBook = Book(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: result.files.single.name.replaceAll('.pdf', ''),
      path: saved.path,
    );

    await BookStorage.addBook(newBook);
    await _loadBooks();
  }

  Future<void> _confirmDelete(Book book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Delete "${book.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await BookStorage.removeBook(book.id);
      await _loadBooks();
    }
  }

  /// 🔥 FORMAT MINUTES → 1h 20m
  String _formatMinutes(int minutes) {
    if (minutes <= 0) return '0m';
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        title: const Text(
          'Your Library',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF5EFE6),
        elevation: 0,
      ),
      body: books.isEmpty
          ? const Center(child: Text('No books yet'))
          : GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.58,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: books.length,
        itemBuilder: (_, i) {
          final book = books[i];
          return GestureDetector(
            onLongPress: () => _confirmDelete(book),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfScreen(book: book),
                ),
              );
              await _loadBooks();
            },
            child: Column(
              children: [
                // 📘 BOOK COVER
                Container(
                  height: 180,
                  width: 130,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.brown.shade600,
                        Colors.brown.shade400
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.menu_book,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),

                      /// 🔥 STREAK BADGE
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: book.streak > 0
                                ? Colors.orange.shade600
                                : Colors.black.withOpacity(0.25),
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 14,
                                color: Colors.white.withOpacity(
                                    book.streak > 0 ? 1 : 0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${book.streak}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(
                                      book.streak > 0 ? 1 : 0.6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      /// 📊 PROGRESS BAR
                      if (book.totalPages > 0)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: FractionallySizedBox(
                            alignment:
                            Alignment.centerLeft,
                            widthFactor: book.progress,
                            child: Container(
                              height: 4,
                              color:
                              Colors.amber.shade300,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 📖 BOOK TITLE
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                // ⏱ PREMIUM READING TIME CAPSULE
                FutureBuilder<List<int>>(
                  future: Future.wait([
                    ReadingTimeStorage.getTodayMinutes(book.id),
                    ReadingTimeStorage.getTotalMinutes(book.id),
                  ]),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }

                    final today = snapshot.data![0];
                    final total = snapshot.data![1];

                    if (today == 0 && total == 0) {
                      return const SizedBox();
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.08),
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer,
                            size: 12,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatMinutes(today)} · ${_formatMinutes(total)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight:
                              FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown.shade600,
        onPressed: _pickPdf,
        child: const Icon(Icons.add),
      ),
    );
  }
}
