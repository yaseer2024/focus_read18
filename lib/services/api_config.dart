import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiConfig {
  static String? baseUrl;

  // 🔒 THIS is the ONLY fixed URL in APK
  // Later move this to VPS / Firebase
  static const String configUrl =
      'https://morphologic-attendantly-nada.ngrok-free.dev/config';

  static Future<void> load() async {
    final res = await http.get(Uri.parse(configUrl));

    if (res.statusCode != 200) {
      throw Exception('Failed to load API config');
    }

    final data = jsonDecode(res.body);
    baseUrl = data['apiBaseUrl'];
  }
}