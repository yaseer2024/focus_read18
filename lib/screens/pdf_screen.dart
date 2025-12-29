import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

import '../models/book.dart';
import '../storage/book_storage.dart';
import '../services/reading_streak.dart';

class PdfScreen extends StatefulWidget {
  final Book book;
  const PdfScreen({super.key, required this.book});

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  late PageController pageController;
  bool darkMode = false;
  bool showUI = true;
  int currentPage = 0;
  int totalPages = 0;
  bool isLoading = true;

  final Map<int, PdfPageImage> _pageCache = {};
  PdfDocument? _pdfDocument;

  @override
  void initState() {
    super.initState();
    currentPage = widget.book.lastPage;
    pageController = PageController(initialPage: widget.book.lastPage);
    _initPdf();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initPdf() async {
    _pdfDocument = await PdfDocument.openFile(widget.book.path);
    setState(() {
      totalPages = _pdfDocument!.pagesCount;
      widget.book.totalPages = totalPages;
      isLoading = false;
    });
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    final books = await BookStorage.load();
    final index = books.indexWhere((b) => b.id == widget.book.id);
    if (index != -1) {
      books[index].lastPage = currentPage;
      books[index].totalPages = totalPages;
      await BookStorage.save(books);
    }
  }

  Future<PdfPageImage?> _loadPage(int pageNumber) async {
    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber];
    }

    final page = await _pdfDocument!.getPage(pageNumber);
    final image = await page.render(
      width: page.width * 2,
      height: page.height * 2,
      format: PdfPageImageFormat.png,
      backgroundColor: '#FFFFFF',
    );
    await page.close();

    if (image != null) _pageCache[pageNumber] = image;
    return image;
  }

  void _toggleUI() {
    setState(() => showUI = !showUI);
    if (showUI) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _toggleDarkMode() {
    setState(() => darkMode = !darkMode);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
        darkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
        darkMode ? Colors.black : const Color(0xFFF5EFE6),
        systemNavigationBarIconBrightness:
        darkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _saveProgress();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    pageController.dispose();
    _pageCache.clear();
    _pdfDocument?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: darkMode ? Colors.black : const Color(0xFFF5EFE6),
      body: Stack(
        children: [
          /// PDF pages (REEL STYLE)
          GestureDetector(
            onTap: _toggleUI,
            child: PageView.builder(
              controller: pageController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              itemCount: totalPages,
              onPageChanged: (page) {
                setState(() => currentPage = page);
                _saveProgress();
                ReadingStreak.markRead(widget.book);
              },
              itemBuilder: (_, index) {
                return FutureBuilder<PdfPageImage?>(
                  future: _loadPage(index + 1),
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Container(
                      color: darkMode ? Colors.black : const Color(0xFFF5EFE6),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: darkMode
                            ? ColorFiltered(
                          colorFilter: const ColorFilter.matrix([
                            -0.9, 0, 0, 0, 255,
                            0, -0.9, 0, 0, 255,
                            0, 0, -0.9, 0, 255,
                            0, 0, 0, 1, 0,
                          ]),
                          child: Image.memory(
                            snap.data!.bytes,
                            fit: BoxFit.contain,
                          ),
                        )
                            : Image.memory(
                          snap.data!.bytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// TOP UI
          if (showUI) ...[
            Positioned(
              top: 40,
              left: 16,
              child: SafeArea(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${currentPage + 1} / $totalPages',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),

            /// DARK / LIGHT TOGGLE 🔥
            Positioned(
              top: 40,
              right: 16,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      darkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color:
                      darkMode ? Colors.amber.shade300 : Colors.white,
                    ),
                    onPressed: _toggleDarkMode,
                  ),
                ),
              ),
            ),

            /// BACK BUTTON
            Positioned(
              top: 40,
              left: 70,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ],

          /// PROGRESS BAR
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              color: Colors.black.withOpacity(0.1),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor:
                totalPages == 0 ? 0 : (currentPage + 1) / totalPages,
                child: Container(
                  color: Colors.brown.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
