import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';

class FreeBooksService {
  // 🔁 Server base URL (LAN IP)
  static const String baseUrl = 'http://192.168.1.14:3000';

  /// 📡 Fetch free books list from server
  static Future<List<Map<String, dynamic>>> fetchBooks() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/free-books'))
          .timeout(const Duration(seconds: 5));

      if (res.statusCode != 200) {
        throw Exception('Failed to load free books');
      }

      final List data = jsonDecode(res.body);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      // 👈 NEVER freeze UI
      return [];
    }
  }

  /// ⬇️ Download PDF from server → save locally → return Book
  static Future<Book> downloadBook(Map<String, dynamic> data) async {
    // ✅ BACKEND SENDS: { id, title }
    final String fileName = data['id'];
    final String url = '$baseUrl/uploads/free_pdfs/$fileName';

    final res = await http.get(Uri.parse(url));

    if (res.statusCode != 200) {
      throw Exception('Failed to download PDF');
    }

    // 📂 Save to app local storage
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(res.bodyBytes);

    // 📘 Return LOCAL book (core-safe)
    return Book(
      id: fileName, // 🔑 stable ID (same as server)
      title: data['title'] ?? 'Untitled',
      path: file.path, // 🔥 local file path
      isRemote: true,
    );
  }
}
