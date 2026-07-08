import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/poi_model.dart';
import '../config.dart';
import 'shared_preferences_service.dart';

class PoiService {
  static Future<List<PoiModel>> getPOIs() async {
    final response = await http.get(Uri.parse('${Config.BASE_URL}/api/poi'));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success']) {
        final List data = jsonResponse['data'];
        return data.map((json) => PoiModel.fromJson(json)).toList();
      }
    }
    throw Exception('Failed to load POIs');
  }

  static Future<PoiModel> createPOI(PoiModel poi) async {
    final token = await SharedPreferencesService.getToken();
    final response = await http.post(
      Uri.parse('${Config.BASE_URL}/api/poi'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(poi.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success']) {
        return PoiModel.fromJson(jsonResponse['data']);
      }
    }
    throw Exception('Failed to create POI: ${response.body}');
  }

  static Future<PoiModel> updatePOI(PoiModel poi) async {
    final token = await SharedPreferencesService.getToken();
    final response = await http.put(
      Uri.parse('${Config.BASE_URL}/api/poi/${poi.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(poi.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success']) {
        return PoiModel.fromJson(jsonResponse['data']);
      }
    }
    throw Exception('Failed to update POI: ${response.body}');
  }

  static Future<void> deletePOI(String id) async {
    final token = await SharedPreferencesService.getToken();
    final response = await http.delete(
      Uri.parse('${Config.BASE_URL}/api/poi/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete POI: ${response.body}');
    }
  }
}
