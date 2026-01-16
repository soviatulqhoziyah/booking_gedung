import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/venue_model.dart';

class VenueService {
  // Gunakan IP Laptop jika pakai HP asli, atau 10.0.2.2 untuk Emulator Android
  final String baseUrl = "http://10.0.2.2:8001/api/venues";

  // --- 1. GET ALL VENUES ---
  Future<List<Venue>> getAllVenues() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body)['data'];
        return jsonResponse.map((data) => Venue.fromJson(data)).toList();
      } else {
        throw Exception('Gagal mengambil data gedung');
      }
    } catch (e) {
      print("Error Get All: $e");
      return [];
    }
  }

  // --- 2. SAVE (CREATE & UPDATE) MENGGUNAKAN MULTIPART ---
  // Fungsi ini menangani upload gambar asli ke Laravel
  Future<bool> saveVenueMultipart(Map<String, String> body, File? imageFile, int? id) async {
    try {
      var url = id != null ? "$baseUrl/$id" : baseUrl;

      // Laravel butuh Method POST untuk pengiriman file (Multipart)
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Jika UPDATE, tambahkan _method PUT (Method Spoofing Laravel)
      if (id != null) {
        request.fields['_method'] = 'PUT';
      }

      // Masukkan semua field teks (name, location, price, etc)
      request.fields.addAll(body);

      // Masukkan file gambar jika user memilih gambar baru
      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'images[]', // Nama key harus sama dengan di Controller Laravel
          imageFile.path,
        ));
      }

      // Kirim permintaan ke server
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error Save Multipart: $e");
      return false;
    }
  }

  // --- 3. DELETE VENUE ---
  Future<bool> deleteVenue(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print("Error Delete: $e");
      return false;
    }
  }

  // --- FUNGSI LAMA (Tetap dipertahankan jika dibutuhkan) ---
  Future<bool> createVenue(Venue venue) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(venue.toJson()),
    );
    return response.statusCode == 201;
  }

  Future<bool> updateVenue(Venue venue) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${venue.id}'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(venue.toJson()),
    );
    return response.statusCode == 200;
  }
}