import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

class ApiService {
  static String baseUrl = "http://192.168.23.131:8000";

  // Escanear imagen y obtener Pokémon
  static Future<Pokemon?> scanImage(File file) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/upload"),
      );
      request.files.add(await http.MultipartFile.fromPath("file", file.path));

      var response = await request.send().timeout(const Duration(seconds: 20));
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        if (data['error'] != null) return null;

        return Pokemon(
          name: data['name'],
          hp: data['hp'],
          maxHp: data['hp'],
          attack: data['attack'],
          defense: data['defense'] ?? 40,
          similarity: data['similarity'] ?? '',
          capturedAt: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error scan: $e');
    }
    return null;
  }

  // Guardar Pokémon capturado en la Raspberry
  static Future<bool> saveCaptured(Pokemon pokemon) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/capture"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(pokemon.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error save: $e');
      return false;
    }
  }

  // Obtener colección guardada
  static Future<List<Pokemon>> getCollection() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/collection"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Pokemon.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error collection: $e');
    }
    return [];
  }

  // Health check
  static Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/health"))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
