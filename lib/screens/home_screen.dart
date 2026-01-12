import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format rupiah
import '../models/venue_model.dart';
import '../services/venue_service.dart';
import 'detail_screen.dart';
import 'form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VenueService _apiService = VenueService();
  late Future<List<Venue>> _venuesFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // Fungsi untuk refresh data (dipakai saat pull-to-refresh atau setelah tambah data)
  Future<void> _refreshData() async {
    setState(() {
      _venuesFuture = _apiService.getAllVenues();
    });
  }

  // Helper format rupiah
  String formatRupiah(int price) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Gedung')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigasi ke FormScreen untuk tambah data
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const FormScreen()));
          _refreshData(); // Refresh setelah kembali
        },
        label: const Text("Tambah Gedung"),
        icon: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<List<Venue>>(
          future: _venuesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Belum ada data gedung."));
            }

            final venues = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: venues.length,
              itemBuilder: (context, index) {
                final venue = venues[index];
                // Desain Kartu Gedung
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      // Ke Detail Screen
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(venue: venue)));
                      _refreshData();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gambar Placeholder (bisa diganti NetworkImage nanti)
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: const Center(child: Icon(Icons.image, size: 64, color: Colors.white)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(venue.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(venue.location, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${formatRupiah(venue.pricePerHour)} / jam",
                                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
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