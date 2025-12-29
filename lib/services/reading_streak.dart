import '../models/book.dart';
import '../storage/book_storage.dart';

class ReadingStreak {
  static Future<void> markRead(Book book) async {
    final today = DateTime.now();
    final todayKey = _dateKey(today);

    final books = await BookStorage.load();
    final index = books.indexWhere((b) => b.id == book.id);
    if (index == -1) return;

    final storedBook = books[index];

    if (storedBook.lastReadDate == todayKey) {
      return; // already counted today
    }

    if (storedBook.lastReadDate == _dateKey(today.subtract(const Duration(days: 1)))) {
      storedBook.streak += 1;
    } else {
      storedBook.streak = 1;
    }

    storedBook.lastReadDate = todayKey;
    await BookStorage.save(books);
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month}-${d.day}';
}
