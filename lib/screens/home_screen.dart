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

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
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
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55, // ✅ MORE HEIGHT
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: books.length,
        itemBuilder: (_, i) {
          final book = books[i];

          return GestureDetector(
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
              mainAxisSize: MainAxisSize.min,
              children: [
                /// 📕 BOOK
                Container(
                  height: 180,
                  width: 130,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.brown.shade600,
                        Colors.brown.shade400,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.menu_book,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                /// 📘 TITLE
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

                /// ⏱️ FIXED HEIGHT CAPSULE AREA
                SizedBox(
                  height: 26, // ✅ prevents overflow
                  child: FutureBuilder(
                    future: Future.wait([
                      ReadingTimeStorage.getTodayMinutes(book.id),
                      ReadingTimeStorage.getTotalMinutes(book.id),
                    ]),
                    builder: (_, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();

                      final today = snapshot.data![0] as int;
                      final total = snapshot.data![1] as int;

                      if (today == 0 && total == 0) {
                        return const SizedBox();
                      }

                      return Wrap(
                        spacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          if (today > 0)
                            _TimeCapsule(
                              label:
                              'Today ${_formatMinutes(today)}',
                              bgColor:
                              Colors.orange.withOpacity(0.15),
                              textColor:
                              Colors.orange.shade800,
                            ),
                          if (total > 0)
                            _TimeCapsule(
                              label:
                              'Total ${_formatMinutes(total)}',
                              bgColor: Colors.blueGrey
                                  .withOpacity(0.12),
                              textColor:
                              Colors.blueGrey.shade700,
                            ),
                        ],
                      );
                    },
                  ),
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

/// 🔹 CAPSULE WIDGET
class _TimeCapsule extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _TimeCapsule({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
