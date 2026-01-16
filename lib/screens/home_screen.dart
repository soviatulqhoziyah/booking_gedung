import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Wajib Import
import '../models/venue_model.dart';
import '../services/venue_service.dart';
import 'detail_screen.dart';
import 'form_screen.dart';
import 'login_screen.dart'; // Sesuaikan jika ada logout

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VenueService _apiService = VenueService();
  late Future<List<Venue>> _venuesFuture;

  // ✅ UBAH JADI STRING (Karena ID MongoDB itu String)
  String _loggedInUserId = "";

  // URL Gambar Gedung (Port 8001)
  final String _imageBaseUrl = "http://10.0.2.2:8001/uploads/";

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Ambil ID User
    _refreshData();
  }

  // --- 1. AMBIL ID USER (STRING) ---
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Gunakan getString karena LoginScreen menyimpannya sebagai String
      _loggedInUserId = prefs.getString('userId') ?? "";
    });
    print("User Login ID: $_loggedInUserId");
  }

  // Fungsi Logout
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen())
      );
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _venuesFuture = _apiService.getAllVenues();
    });
  }

  String formatRupiah(int price) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  // Helper Gambar
  Widget _buildVenueImage(List<String> images) {
    if (images.isEmpty) {
      return Container(color: Colors.grey.shade300, child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey));
    }
    String firstImage = images.first;
    String finalUrl = firstImage.startsWith('http') ? firstImage : "$_imageBaseUrl$firstImage";

    return Image.network(
      finalUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Gedung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Logout",
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const FormScreen()));
          _refreshData();
        },
        label: const Text("Tambah Gedung"),
        icon: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<List<Venue>>(
          future: _venuesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada data gedung."));

            final venues = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: venues.length,
              itemBuilder: (context, index) {
                final venue = venues[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      // Kirim ID String ke Detail
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(
                            venue: venue,
                            currentUserId: _loggedInUserId, // ✅ Kirim String
                          ),
                        ),
                      );
                      _refreshData();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: _buildVenueImage(venue.images),
                          ),
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
                                  const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(venue.location, style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${formatRupiah(venue.pricePerHour)} / jam", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text("Kapasitas: ${venue.capacity}", style: const TextStyle(fontSize: 12, color: Colors.blue)),
                                ],
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