import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';
import '../storage/book_storage.dart';
import 'pdf_screen.dart';
import 'free_books_screen.dart';

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
    final loaded = await BookStorage.load();
    setState(() {
      books = loaded;
      isLoading = false;
    });
  }

  Book? _getContinueReadingBook() {
    final readingBooks = books.where((b) => b.lastPage > 0).toList();
    if (readingBooks.isEmpty) return null;

    readingBooks.sort((a, b) => b.lastPage.compareTo(a.lastPage));
    return readingBooks.first;
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;

    final file = File(result.files.single.path!);
    final dir = await getApplicationDocumentsDirectory();

    final saved = await file.copy(
      '${dir.path}/${result.files.single.name}',
    );

    final book = Book(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: result.files.single.name.replaceAll('.pdf', ''),
      path: saved.path,
    );

    await BookStorage.addBook(book);
    await _loadBooks();
  }

  Future<void> _deleteBook(Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete book'),
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

    if (ok == true) {
      await BookStorage.removeBook(book.id);
      await _loadBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final continueBook = _getContinueReadingBook();

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5EFE7),
        title: const Text(
          'Your Library',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3E2723),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _FreeBooksHeroCard(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FreeBooksScreen(),
                ),
              );
              await _loadBooks();
            },
          ),

          if (continueBook != null)
            _ContinueReadingCard(
              book: continueBook,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfScreen(book: continueBook),
                  ),
                );
                await _loadBooks();
              },
            ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              itemCount: books.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 0.63,
              ),
              itemBuilder: (_, i) {
                final book = books[i];
                return _BookCard(
                  book: book,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfScreen(book: book),
                      ),
                    );
                    await _loadBooks();
                  },
                  onDelete: () => _deleteBook(book),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B4513),
        onPressed: _pickPdf,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/* ---------------- FREE BOOKS ---------------- */

class _FreeBooksHeroCard extends StatelessWidget {
  final VoidCallback onTap;
  const _FreeBooksHeroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
            ),
          ),
          child: Row(
            children: const [
              Icon(Icons.auto_stories, color: Colors.white, size: 34),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Free Books • Hand-picked',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------- CONTINUE READING ---------------- */

class _ContinueReadingCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _ContinueReadingCard({
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = book.progress.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF065F46), Color(0xFF10B981)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Continue Reading',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white24,
                valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------- BOOK CARD (STREAK POWERED) ---------------- */

class _BookCard extends StatefulWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookCard({
    required this.book,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<_BookCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LinearGradient _streakGradient(int streak) {
    if (streak >= 7) {
      return const LinearGradient(
        colors: [Color(0xFFDC2626), Color(0xFFFB7185)],
      );
    } else if (streak >= 4) {
      return const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
      );
    } else if (streak > 0) {
      return const LinearGradient(
        colors: [Color(0xFFEA580C), Color(0xFFF97316)],
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF8B4513), Color(0xFFB87333)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final progress = book.progress.clamp(0.0, 1.0);
    final firstLetter =
    book.title.isNotEmpty ? book.title[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onDelete,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final glow = book.streak > 0
              ? 6 + (_controller.value * 6)
              : 0.0;

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: book.streak > 0
                  ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.35),
                  blurRadius: glow,
                  spreadRadius: 1,
                )
              ]
                  : [],
            ),
            child: Material(
              elevation: 7,
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _streakGradient(book.streak),
                          ),
                          child: Center(
                            child: Text(
                              firstLetter,
                              style: const TextStyle(
                                fontSize: 52,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.black12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (book.streak > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              '${book.streak}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
