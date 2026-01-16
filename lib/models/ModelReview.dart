// To parse this JSON data, do
//
//     final modelReview = modelReviewFromJson(jsonString);

import 'dart:convert';

List<ModelReview> modelReviewFromJson(String str) => List<ModelReview>.from(json.decode(str).map((x) => ModelReview.fromJson(x)));

String modelReviewToJson(List<ModelReview> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ModelReview {
  int rating;
  int gedungId;
  int id;
  DateTime createdAt;
  String comment;
  String userName;

  ModelReview({
    required this.rating,
    required this.gedungId,
    required this.id,
    required this.createdAt,
    required this.comment,
    required this.userName,
  });

  factory ModelReview.fromJson(Map<String, dynamic> json) => ModelReview(
    rating: json["rating"],
    gedungId: json["gedung_id"],
    id: json["id"],
    createdAt: DateTime.parse(json["created_at"]),
    comment: json["comment"],
    userName: json["user_name"],
  );

  Map<String, dynamic> toJson() => {
    "rating": rating,
    "gedung_id": gedungId,
    "id": id,
    "created_at": createdAt.toIso8601String(),
    "comment": comment,
    "user_name": userName,
  };
}
