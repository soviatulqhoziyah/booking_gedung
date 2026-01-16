import 'dart:convert';
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
}