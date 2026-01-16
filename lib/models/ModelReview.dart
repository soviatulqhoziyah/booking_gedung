import 'dart:convert';

List<ModelReview> modelReviewFromJson(String str) => List<ModelReview>.from(json.decode(str).map((x) => ModelReview.fromJson(x)));

String modelReviewToJson(List<ModelReview> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ModelReview {
  int id;
  int venueId;
  String userId; // ✅ Kita paksa jadi String
  int rating;
  String comment;

  ModelReview({
    required this.id,
    required this.venueId,
    required this.userId,
    required this.rating,
    required this.comment,
  });

  factory ModelReview.fromJson(Map<String, dynamic> json) {
    return ModelReview(
      id: json["id"] ?? 0,
      venueId: json["venue_id"] ?? 0,

      // 👇 BAGIAN PENTING: Handle konversi otomatis biar gak error
      userId: (json["user_id"] ?? "0").toString(),

      // Handle rating kalau server kirim string "5" bukan angka 5
      rating: int.tryParse(json["rating"].toString()) ?? 0,

      comment: json["comment"] ?? "-",
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "venue_id": venueId,
    "user_id": userId,
    "rating": rating,
    "comment": comment,
  };
}