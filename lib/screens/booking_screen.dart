import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/ModelBooking.dart';

class BookingPage extends StatefulWidget {
  final int idGedung;
  final String namaGedung;
  final double hargaPerJam;
  final String userName; // ✅ 1. Terima Data Nama User

  const BookingPage({
    super.key,
    required this.idGedung,
    required this.namaGedung,
    required this.hargaPerJam,
    required this.userName, // ✅ Wajib diisi dari halaman sebelumnya
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // ❌ Hapus _nameController, tidak butuh lagi

  int _selectedDuration = 1;
  bool _isLoading = false;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitBooking() async {
    // ❌ Tidak perlu validasi nama kosong, karena ambil dari akun

    setState(() => _isLoading = true);

    try {
      final int priceInt = widget.hargaPerJam.toInt();
      final String url = "http://10.0.2.2:8002/api/bookings?pricePerHour=$priceInt";

      DateTime finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      String formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(finalDateTime);

      final Map<String, dynamic> requestBody = {
        "gedungId": widget.idGedung,
        "customerName": widget.userName, // ✅ 2. Pakai nama dari Login
        "bookingDate": formattedDate,
        "durationHours": _selectedDuration,
        "totalPrice": (widget.hargaPerJam * _selectedDuration).toInt(),
        "paymentProof": null,
        "status": "PENDING"
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = BookingModel.fromJson(jsonDecode(response.body));
        if (mounted) _showSuccessDialog(result);
      } else {
        throw "Error ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(BookingModel data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Berhasil Dipesan!"),
        content: Text("ID: ${data.id}\nTanggal: ${DateFormat('dd MMM yyyy, HH:mm').format(data.bookingDate)}"),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("Selesai"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalHarga = (widget.hargaPerJam * _selectedDuration).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Konfirmasi Pesanan"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.namaGedung, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text("Gedung ID: ${widget.idGedung}", style: const TextStyle(color: Colors.grey)),
            const Divider(height: 40),

            const Text("Nama Pemesan", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // ✅ 3. Tampilkan Nama User (Read Only / Tidak bisa diedit)
            TextFormField(
              initialValue: widget.userName, // Tampilkan nama login
              readOnly: true, // Tidak bisa diketik
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade100, // Warna abu-abu menandakan disabled
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 25),

            const Text("Pilih Tanggal & Waktu Sewa", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            const Text("Durasi Sewa", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<int>(
              value: _selectedDuration,
              items: [1, 2, 3, 5, 8].map((e) => DropdownMenuItem(value: e, child: Text("$e Jam"))).toList(),
              onChanged: (v) => setState(() => _selectedDuration = v!),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Pembayaran", style: TextStyle(fontSize: 16)),
                  Text("Rp $totalHarga", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _isLoading ? null : _submitBooking,
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("BOOKING SEKARANG"),
        ),
      ),
    );
  }
}