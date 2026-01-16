import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ModelBooking.dart';

class BookingService {
  static const String baseUrl = "http://10.0.2.2:8002/api/bookings";

  Future<BookingModel?> createBooking({
    required int gedungId,
    required String name,
    required int duration,
    required double price // Ini adalah HARGA PER JAM (bukan total)
  }) async {
    try {
      // 1. Siapkan Data JSON (Body)
      final Map<String, dynamic> data = {
        "gedungId": gedungId,
        "customerName": name,
        // Format tanggal sudah benar (tanpa milidetik)
        "bookingDate": DateTime.now().toIso8601String().split('.')[0],
        "durationHours": duration,
        "status": "PENDING"
        // Note: 'totalPrice' tidak perlu dikirim di JSON,
        // karena Backend akan menghitungnya sendiri berdasarkan (duration * price)
      };

      print("Body JSON: ${jsonEncode(data)}");

      // 2. SIAPKAN URL DENGAN QUERY PARAMETER (WAJIB!)
      // Ini akan mengubah URL menjadi: .../api/bookings?pricePerHour=50000
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'pricePerHour': price.toString(),
      });

      print("Hit URL: $uri"); // Cek di terminal, harus ada tanda tanya (?)

      // 3. Kirim Request
      final response = await http.post(
        uri, // Pakai URI yang sudah ada parameternya
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(data),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Server: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return BookingModel.fromJson(jsonDecode(response.body));
      } else {
        return null;
      }
    } catch (e) {
      print("Network Error: $e");
      return null;
    }
  }

  Future<List<BookingModel>> getHistory(String name) async {
    try {
      // Endpoint sesuai Controller Spring Boot tadi: /user/{name}
      final response = await http.get(Uri.parse('$baseUrl/user/$name'));

      print("Request ke: $baseUrl/user/$name");
      print("Status: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        return bookingModelFromJson(response.body);
      } else {
        return []; // Jika kosong atau error
      }
    } catch (e) {
      print("Error Fetch History: $e");
      return [];
    }
  }

  Future<bool> uploadPaymentProof(int bookingId, File imageFile) async {
    try {
      // Endpoint: POST /api/bookings/{id}/upload
      var request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/$bookingId/upload')
      );

      // Masukkan file ke request
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      // Kirim
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Upload Status: ${response.statusCode}");
      print("Upload Response: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("Error Upload: $e");
      return false;
    }
  }
  // ✅ FUNGSI BARU: Ambil SEMUA Booking (Khusus Admin)
  Future<List<BookingModel>> getAllBookings() async {
    try {
      // Endpoint: GET /api/bookings
      final response = await http.get(Uri.parse(baseUrl));

      print("Admin Fetch All: $baseUrl");
      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        return bookingModelFromJson(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print("Error Admin Fetch: $e");
      return [];
    }
  }

  Future<bool> updateBookingStatus(int id, String newStatus) async {
    try {
      // Kita gunakan query parameter (?status=...) sesuai backend
      final uri = Uri.parse('$baseUrl/$id').replace(queryParameters: {
        'status': newStatus,
      });

      print("Hit Update: $uri");

      final response = await http.put(uri);

      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("Error Update Status: $e");
      return false;
    }
  }
}
