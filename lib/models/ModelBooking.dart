import 'dart:convert';
List<BookingModel> bookingModelFromJson(String str) =>
    List<BookingModel>.from(json.decode(str).map((x) => BookingModel.fromJson(x)));

class BookingModel {
  final int id;
  final int gedungId;
  final String customerName;
  final DateTime bookingDate;
  final int durationHours;
  final int totalPrice; // Pastikan int
  final String? paymentProof;
  final String status;

  BookingModel({
    required this.id,
    required this.gedungId,
    required this.customerName,
    required this.bookingDate,
    required this.durationHours,
    required this.totalPrice,
    this.paymentProof,
    required this.status,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      gedungId: json['gedungId'],
      customerName: json['customerName'],
      bookingDate: DateTime.parse(json['bookingDate']),
      durationHours: json['durationHours'],
      totalPrice: (json['totalPrice'] as num).toInt(), // Paksa ke int
      paymentProof: json['paymentProof'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gedungId': gedungId,
      'customerName': customerName,
      'bookingDate': bookingDate.toIso8601String(),
      'durationHours': durationHours,
      'totalPrice': totalPrice,
      'paymentProof': paymentProof,
      'status': status,
    };
  }
}