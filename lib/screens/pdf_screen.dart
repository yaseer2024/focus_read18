import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

import '../models/book.dart';
import '../storage/book_storage.dart';
import '../services/reading_streak.dart';
import '../storage/reading_time_storage.dart';

class PdfScreen extends StatefulWidget {
  final Book book;
  const PdfScreen({super.key, required this.book});

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen>
    with WidgetsBindingObserver {
  late PageController pageController;

  bool darkMode = false;
  bool showUI = true;
  bool isLoading = true;

  int currentPage = 0;
  int totalPages = 0;
  int previousPage = 0;

  final Map<int, PdfPageImage> _pageCache = {};
  final Map<int, Future<PdfPageImage?>> _futureCache = {};
  PdfDocument? _pdfDocument;

  // 🔥 READING TIME
  final Stopwatch _sessionWatch = Stopwatch();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    currentPage = widget.book.lastPage;
    previousPage = widget.book.lastPage;
    pageController = PageController(initialPage: widget.book.lastPage);

    _initPdf();

    _sessionWatch.start(); // 🔥 START SESSION TIMER

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _sessionWatch.stop(); // 🔥 pause
    } else if (state == AppLifecycleState.resumed) {
      _sessionWatch.start(); // 🔥 resume
    }
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

  Future<PdfPageImage?> _loadPage(int pageNumber) {
    if (_pageCache.containsKey(pageNumber)) {
      return Future.value(_pageCache[pageNumber]);
    }

    if (_futureCache.containsKey(pageNumber)) {
      return _futureCache[pageNumber]!;
    }

    final future = () async {
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
    }();

    _futureCache[pageNumber] = future;
    return future;
  }

  void _toggleUI() => setState(() => showUI = !showUI);
  void _toggleDarkMode() => setState(() => darkMode = !darkMode);

  Future<void> _saveReadingTime() async {
    _sessionWatch.stop();
    final minutes = _sessionWatch.elapsed.inMinutes;
    if (minutes > 0) {
      await ReadingTimeStorage.addMinutes(
        widget.book.id,
        minutes,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _saveProgress();
    _saveReadingTime(); // 🔥 SAVE SESSION TIME

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    pageController.dispose();
    _pageCache.clear();
    _futureCache.clear();
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
          Listener(
            onPointerDown: (_) => _toggleUI(),
            child: PageView.builder(
              controller: pageController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              itemCount: totalPages,
              onPageChanged: (page) async {
                HapticFeedback.selectionClick();

                if (page > previousPage) {
                  await ReadingStreak.markRead(widget.book);
                }

                previousPage = page;
                setState(() => currentPage = page);
                await _saveProgress();
              },
              itemBuilder: (_, index) {
                return FutureBuilder<PdfPageImage?>(
                  future: _loadPage(index + 1),
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    return Container(
                      color: darkMode
                          ? Colors.black
                          : const Color(0xFFF5EFE6),
                      padding:
                      const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: darkMode
                            ? ColorFiltered(
                          colorFilter:
                          const ColorFilter.matrix([
                            -1, 0, 0, 0, 255,
                            0, -1, 0, 0, 255,
                            0, 0, -1, 0, 255,
                            0, 0, 0, 1, 0,
                          ]),
                          child:
                          Image.memory(snap.data!.bytes),
                        )
                            : Image.memory(snap.data!.bytes),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (showUI)
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    _icon(Icons.arrow_back,
                            () => Navigator.pop(context)),
                    _pill('${currentPage + 1} / $totalPages'),
                    _icon(
                      darkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      _toggleDarkMode,
                      color: darkMode
                          ? Colors.amber.shade300
                          : Colors.white,
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FractionallySizedBox(
              widthFactor: totalPages == 0
                  ? 0
                  : (currentPage + 1) / totalPages,
              child: Container(
                height: 3,
                color: Colors.brown.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _icon(IconData icon, VoidCallback onTap,
      {Color color = Colors.white}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onTap,
      ),
    );
  }
}
