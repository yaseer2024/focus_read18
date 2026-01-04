import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';
import 'api_config.dart';

class FreeBooksService {

  static String get baseUrl {
    if (ApiConfig.baseUrl == null) {
      throw Exception('API Base URL not loaded');
    }
    return ApiConfig.baseUrl!;
  }

  /// 📡 Fetch free books list
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
    } catch (_) {
      return [];
    }
  }

  /// ⬇️ Download PDF → save locally
  static Future<Book> downloadBook(Map<String, dynamic> data) async {
    final String fileName = data['id'];
    final String url = '$baseUrl/free_pdfs/$fileName';

    final res = await http.get(Uri.parse(url));

    if (res.statusCode != 200) {
      throw Exception('Failed to download PDF');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(res.bodyBytes);

    return Book(
      id: fileName,
      title: data['title'] ?? 'Untitled',
      path: file.path,
      isRemote: true,
    );
  }
}