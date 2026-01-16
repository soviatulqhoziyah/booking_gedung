import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ModelUser.dart';

class UserService {
  // Base URL untuk Auth (Login/Register)
  static const String baseUrl = "http://10.0.2.2:3001/api/auth";

  Future<Map<String, dynamic>> register(Datum user) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(user.toJson()),
      );
      Map<String, dynamic> data = jsonDecode(response.body);
      data['statusCode'] = response.statusCode;
      return data;
    } catch (e) {
      return {"message": "Koneksi Gagal", "statusCode": 500};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      Map<String, dynamic> data = jsonDecode(response.body);
      data['statusCode'] = response.statusCode;
      return data;
    } catch (e) {
      return {"message": "Koneksi Gagal", "statusCode": 500};
    }
  }

  // 👇👇👇 PERBAIKAN DI SINI: UBAH 'int' JADI 'String' 👇👇👇
  Future<String> getUserName(String id) async { // ✅ String, bukan int
    try {
      // ✅ Port 3001 (User Service)
      final url = Uri.parse("http://10.0.2.2:3001/api/users/$id");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Cek struktur JSON (username dari MongoDB)
        // Prioritaskan 'username', kalau tidak ada cek 'name'
        if (data['username'] != null) {
          return data['username'];
        } else if (data['data'] != null && data['data']['username'] != null) {
          return data['data']['username'];
        } else if (data['name'] != null) {
          return data['name'];
        }
      }
      // Return sebagian ID jika nama tidak ketemu
      return "User #${id.substring(0, 4)}...";
    } catch (e) {
      print("Gagal ambil nama: $e");
      return "User Error";
    }
  }
}