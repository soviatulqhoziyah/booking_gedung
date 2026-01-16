import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // ✅ WAJIB IMPORT
import '../models/ModelBooking.dart';
import '../services/BookingServices.dart';


class HistoryScreen extends StatefulWidget {
  final String userName;

  const HistoryScreen({super.key, required this.userName});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final BookingService _bookingService = BookingService();
  late Future<List<BookingModel>> _historyFuture;
  final ImagePicker _picker = ImagePicker(); // Instance Image Picker

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _historyFuture = _bookingService.getHistory(widget.userName);
    });
  }

  // --- LOGIKA UPLOAD BUKTI BAYAR ---
  Future<void> _pickAndUpload(int bookingId) async {
    // 1. Pilih Gambar dari Galeri
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // Tampilkan Loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );
      }

      // 2. Upload ke Backend
      bool success = await _bookingService.uploadPaymentProof(bookingId, imageFile);

      // Tutup Loading
      if (mounted) Navigator.pop(context);

      // 3. Cek Hasil
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bukti bayar berhasil diupload!"), backgroundColor: Colors.green),
          );
        }
        _refreshData(); // Refresh agar status berubah jadi PAID
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal upload bukti bayar."), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  String formatRupiah(int price) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID': return Colors.green;
      case 'PENDING': return Colors.orange;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Pesanan"),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<List<BookingModel>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text("Gagal memuat data: ${snapshot.error}"));
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, size: 80, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text("Belum ada riwayat booking."),
                    Text("User: ${widget.userName}", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            final bookings = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final item = bookings[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: ID & Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Order #${item.id}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(item.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _getStatusColor(item.status)),
                              ),
                              child: Text(
                                item.status,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getStatusColor(item.status)),
                              ),
                            )
                          ],
                        ),
                        const Divider(),

                        // Detail Info
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.event, color: Colors.teal),
                          ),
                          title: Text(formatDate(item.bookingDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Durasi: ${item.durationHours} Jam"),
                        ),

                        // Harga
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Tagihan:", style: TextStyle(fontSize: 14)),
                            Text(formatRupiah(item.totalPrice), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ✅ TOMBOL UPLOAD BUKTI (Hanya Muncul Jika PENDING)
                        if (item.status == 'PENDING')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _pickAndUpload(item.id),
                              icon: const Icon(Icons.upload_file),
                              label: const Text("Upload Bukti Bayar"),
                            ),
                          )
                        else if (item.status == 'PAID')
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Center(
                              child: Text("✅ Pembayaran Lunas", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ),
                          )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}