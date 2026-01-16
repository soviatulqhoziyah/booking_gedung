import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ModelReview.dart';

class ReviewService {
  // Pastikan URL ini benar (Port Backend Python kamu)
  static const String baseUrl = "http://10.0.2.2:7000";

  // GET: Ambil review
  Future<List<ModelReview>> getReviews(int venueId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reviews/$venueId'));

      if (response.statusCode == 200) {
        return modelReviewFromJson(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching reviews: $e");
      return [];
    }
  }

  // 👇👇 PERBAIKAN DI SINI 👇👇
  // Ubah 'int userId' menjadi 'String userId'
  Future<bool> postReview(int venueId, String userId, int rating, String comment) async {
    try {
      final Map<String, dynamic> data = {
        "venue_id": venueId,
        "user_id": userId, // ✅ Sekarang bisa terima String
        "rating": rating,
        "comment": comment
      };

      final response = await http.post(
        Uri.parse('$baseUrl/reviews/'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );

      return response.statusCode == 201;
    } catch (e) {
      print("Error posting review: $e");
      return false;
    }
  }
}