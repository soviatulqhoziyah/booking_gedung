import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ModelReview.dart';

class ReviewService {
  final String baseUrl = "http://10.0.2.2:7000"; // Sesuaikan jika pakai emulator

  Future<List<ModelReview>> getReviews(int gedungId) async {
    final response = await http.get(Uri.parse("$baseUrl/reviews/$gedungId"));
    if (response.statusCode == 200) {
      return modelReviewFromJson(response.body);
    }
    return [];
  }

  Future<bool> postReview(int gedungId, String userName, int rating, String comment) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reviews"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "gedung_id": gedungId,
        "user_name": userName,
        "rating": rating,
        "comment": comment,
      }),
    );
    return response.statusCode == 200;
  }
}