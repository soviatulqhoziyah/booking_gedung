import 'dart:convert';

ModelUser modelUserFromJson(String str) => ModelUser.fromJson(json.decode(str));

String modelUserToJson(ModelUser data) => json.encode(data.toJson());

class ModelUser {
  String message;
  int? total;
  List<Datum> data;

  ModelUser({
    required this.message,
    this.total,
    required this.data,
  });

  factory ModelUser.fromJson(Map<String, dynamic> json) => ModelUser(
    message: json["message"],
    total: json["total"],
    data: json["data"] is List
        ? List<Datum>.from(json["data"].map((x) => Datum.fromJson(x)))
        : (json["data"] != null ? [Datum.fromJson(json["data"])] : []),
  );

  Map<String, dynamic> toJson() => {
    "message": message,
    "total": total,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class Datum {
  String? id;
  String username;
  String email;
  String? password;
  String noHp;
  String alamat;
  String? role; // <--- TAMBAHKAN FIELD ROLE DI SINI
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  Datum({
    this.id,
    required this.username,
    required this.email,
    this.password,
    required this.noHp,
    required this.alamat,
    this.role, // <--- TAMBAHKAN DI CONSTRUCTOR
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    id: json["_id"],
    username: json["username"] ?? "",
    email: json["email"] ?? "",
    password: json["password"],
    noHp: json["no_hp"] ?? "",
    alamat: json["alamat"] ?? "",
    role: json["role"] ?? "user", // <--- AMBIL DARI JSON (Default 'user')
    createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : null,
    updatedAt: json["updatedAt"] != null ? DateTime.parse(json["updatedAt"]) : null,
    v: json["__v"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "username": username,
    "email": email,
    "password": password,
    "no_hp": noHp,
    "alamat": alamat,
    "role": role, // <--- SERALISASI KE JSON
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
  };
}