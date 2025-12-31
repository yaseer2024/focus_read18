import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';

class FreeBooksService {
  // 🔁 CHANGE IP IF SERVER CHANGES
  static const String baseUrl = 'http://192.168.1.14:3000';

  /// 📡 Fetch free books list from server
  static Future<List<Map<String, dynamic>>> fetchBooks() async {
    final res = await http.get(Uri.parse('$baseUrl/free-books'));

    if (res.statusCode != 200) {
      throw Exception('Failed to load free books');
    }

    final List data = jsonDecode(res.body);
    return data.cast<Map<String, dynamic>>();
  }

  /// ⬇️ Download PDF and convert to LOCAL Book
  static Future<Book> downloadBook(Map<String, dynamic> data) async {
    final String fileName = data['id'];
    final String url = '$baseUrl/uploads/free_pdfs/$fileName';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to download PDF');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');

    await file.writeAsBytes(response.bodyBytes);

    return Book(
      id: fileName, // 🔑 SAME id avoids duplicates
      title: data['title'],
      path: file.path, // 🔥 LOCAL PATH (CORE SAFE)
    );
  }
}
