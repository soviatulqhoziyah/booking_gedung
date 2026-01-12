import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/venue_model.dart';

class VenueService {
  // GANTI localhost dengan 10.0.2.2 jika pakai Emulator Android
  final String baseUrl = "http://10.0.2.2:8001/api/venues";

  // READ (GET All)
  Future<List<Venue>> getAllVenues() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      // Diasumsikan respon Laravel dibungkus dalam key 'data'
      List jsonResponse = json.decode(response.body)['data'];
      return jsonResponse.map((data) => Venue.fromJson(data)).toList();
    } else {
      throw Exception('Gagal mengambil data gedung');
    }
  }

  // CREATE (POST)
  Future<bool> createVenue(Venue venue) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(venue.toJson()),
    );
    return response.statusCode == 201;
  }

  // UPDATE (PUT)
  Future<bool> updateVenue(Venue venue) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${venue.id}'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(venue.toJson()),
    );
    return response.statusCode == 200;
  }

  // DELETE (DELETE)
  Future<bool> deleteVenue(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    return response.statusCode == 200;
  }
}