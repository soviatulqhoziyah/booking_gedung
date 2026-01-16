import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ModelBooking.dart';
import '../services/BookingServices.dart';


class AdminBookingScreen extends StatefulWidget {
  const AdminBookingScreen({super.key});

  @override
  State<AdminBookingScreen> createState() => _AdminBookingScreenState();
}

class _AdminBookingScreenState extends State<AdminBookingScreen> {
  final BookingService _bookingService = BookingService();
  late Future<List<BookingModel>> _bookingsFuture;

  // URL Gambar Bukti Bayar (Sesuaikan IP backend)
  final String _paymentBaseUrl = "http://10.0.2.2:8002/uploads/";

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _bookingsFuture = _bookingService.getAllBookings();
    });
  }

  // --- LOGIKA UPDATE STATUS (TERIMA / TOLAK) ---
  Future<void> _updateStatus(int id, String status) async {
    // 1. Tampilkan Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    // 2. Panggil Service
    bool success = await _bookingService.updateBookingStatus(id, status);

    // 3. Tutup Loading
    if (mounted) Navigator.pop(context);

    // 4. Cek Hasil
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status berhasil diubah ke $status"),
            backgroundColor: status == 'CONFIRMED' ? Colors.green : Colors.red,
          ),
        );
      }
      _refreshData(); // Refresh list agar tombol hilang
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal update status"), backgroundColor: Colors.red),
        );
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
      case 'CONFIRMED': return Colors.green;
      case 'PAID': return Colors.blue;
      case 'PENDING': return Colors.orange;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  // Pop-up Lihat Gambar
  void _showPaymentProof(String fileName) {
    // 1. Buat variabel URL lengkap
    String fullUrl = "$_paymentBaseUrl$fileName";

    // 2. CEK DI TERMINAL (Bagian Run/Debug di bawah)
    print("========================================");
    print("SEDANG MENCOBA BUKA GAMBAR:");
    print(fullUrl);
    print("========================================");

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text("Bukti Pembayaran"),
              leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
            ),
            InteractiveViewer(
              child: Image.network(
                fullUrl, // Pakai variabel tadi
                // Tambahkan loading builder agar kelihatan kalau lagi loading
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  // Print errornya ke terminal biar ketahuan kenapa gagal
                  print("GAGAL LOAD GAMBAR: $error");
                  return Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text("Gagal memuat gambar", style: TextStyle(color: Colors.grey.shade600)),
                        // Tampilkan URL di layar biar gampang dicek
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(fullUrl, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Pesanan (Admin)"),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<List<BookingModel>>(
          future: _bookingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada pesanan masuk."));

            final bookings = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final item = bookings[index];

                // Cek apakah status sudah Final?
                bool isFinal = item.status == 'CONFIRMED' || item.status == 'CANCELLED';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(item.status).withOpacity(0.2),
                      child: Icon(
                        item.status == 'CONFIRMED' ? Icons.check_circle :
                        item.status == 'CANCELLED' ? Icons.cancel : Icons.receipt,
                        color: _getStatusColor(item.status),
                      ),
                    ),
                    title: Text(item.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${formatDate(item.bookingDate)}\nID: ${item.id} | Gedung: ${item.gedungId}"),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: _getStatusColor(item.status), borderRadius: BorderRadius.circular(8)),
                      child: Text(item.status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Durasi Sewa"), Text("${item.durationHours} Jam")]),
                            const SizedBox(height: 8),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total Tagihan"), Text(formatRupiah(item.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))]),
                            const Divider(height: 20),

                            // TOMBOL LIHAT GAMBAR (Hanya jika status PAID)
                            // (Pastikan field paymentProof ada di ModelBooking kamu, jika belum ada, comment dulu bagian ini)
                            if (item.status == 'PAID')
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    if (item.paymentProof != null && item.paymentProof!.isNotEmpty) {
                                      _showPaymentProof(item.paymentProof!);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Gambar tidak ditemukan di server"))
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.image),
                                  label: const Text("Lihat Bukti Bayar"),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                                ),
                              ),

                            // ✅ TOMBOL AKSI (TERIMA / TOLAK)
                            // Hanya muncul jika belum Final (masih PENDING atau PAID)
                            if (!isFinal)
                              Row(
                                children: [
                                  // TOMBOL TOLAK
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, elevation: 0),
                                      onPressed: () => _updateStatus(item.id, "CANCELLED"),
                                      child: const Text("TOLAK"),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // TOMBOL TERIMA
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                      onPressed: () => _updateStatus(item.id, "CONFIRMED"),
                                      child: const Text("TERIMA"),
                                    ),
                                  ),
                                ],
                              )
                            else
                            // INFO STATUS FINAL
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(item.status == 'CONFIRMED' ? Icons.check : Icons.close, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text("Pesanan ini sudah ${item.status}", style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              )
                          ],
                        ),
                      )
                    ],
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