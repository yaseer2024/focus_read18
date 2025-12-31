import 'package:shared_preferences/shared_preferences.dart';

class ReadingTimeStorage {
  static String _totalKey(String bookId) => 'reading_time_total_$bookId';
  static String _todayKey(String bookId) => 'reading_time_today_$bookId';
  static const _lastDateKey = 'reading_time_last_date';

  // Save minutes
  static Future<void> addMinutes(String bookId, int minutes) async {
    final prefs = await SharedPreferences.getInstance();

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString(_lastDateKey);

    if (lastDate != today) {
      await prefs.setInt(_todayKey(bookId), 0);
      await prefs.setString(_lastDateKey, today);
    }

    final total = prefs.getInt(_totalKey(bookId)) ?? 0;
    final todayMinutes = prefs.getInt(_todayKey(bookId)) ?? 0;

    await prefs.setInt(_totalKey(bookId), total + minutes);
    await prefs.setInt(_todayKey(bookId), todayMinutes + minutes);
  }

  static Future<int> getTotalMinutes(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalKey(bookId)) ?? 0;
  }

  static Future<int> getTodayMinutes(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_todayKey(bookId)) ?? 0;
  }
}