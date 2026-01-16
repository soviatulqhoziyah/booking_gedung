import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/venue_model.dart';
import '../services/venue_service.dart';
import 'detail_screen.dart';
import 'form_screen.dart';
import 'login_screen.dart';
import 'history_screen.dart';       // File user history
import 'admin_booking_screen.dart'; // ✅ File admin history
import 'profile_screen.dart';       // ✅ File profil & logout

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VenueService _apiService = VenueService();
  late Future<List<Venue>> _venuesFuture;

  // Data User
  String _loggedInUserId = "";
  String _loggedInUserName = "";
  String _loggedInUserRole = "user";

  // State Navigasi Bawah
  int _selectedIndex = 0;
  final String _imageBaseUrl = "http://10.0.2.2:8001/uploads/";

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _refreshData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedInUserId = prefs.getString('userId') ?? "";
      _loggedInUserName = prefs.getString('userName') ?? "User";
      _loggedInUserRole = prefs.getString('userRole') ?? "user";
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _venuesFuture = _apiService.getAllVenues();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String formatRupiah(int price) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  // --- WIDGET LIST GEDUNG (Tab Home) ---
  Widget _buildVenueList() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Gedung'),
        automaticallyImplyLeading: false, // Hilangkan back button
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
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(
                            venue: venue,
                            currentUserId: _loggedInUserId,
                            currentUserName: _loggedInUserName,
                            userRole: _loggedInUserRole,
                          ),
                        ),
                      );
                      if (result == true) _refreshData();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: venue.images.isNotEmpty
                                ? Image.network(
                              venue.images.first.startsWith('http')
                                  ? venue.images.first
                                  : "$_imageBaseUrl${venue.images.first}",
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, _) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                            )
                                : Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)),
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
                                  Text("Kap: ${venue.capacity}", style: const TextStyle(fontSize: 12, color: Colors.blue)),
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
      // ✅ TOMBOL TAMBAH (Hanya Muncul Jika Admin)
      floatingActionButton: (_loggedInUserRole == 'admin')
          ? FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const FormScreen()));
          _refreshData();
        },
        label: const Text("Tambah"),
        icon: const Icon(Icons.add),
      )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- 1. TENTUKAN MENU BERDASARKAN ROLE ---
    List<Widget> bodyContent;
    List<BottomNavigationBarItem> navItems;

    if (_loggedInUserRole == 'admin') {
      // === LAYOUT ADMIN ===
      bodyContent = [
        _buildVenueList(),           // Index 0: Home (Ada Tombol Tambah)
        const AdminBookingScreen(),  // Index 1: Booking Masuk (File Baru)
        ProfileScreen(               // Index 2: Profil & Logout
          userId: _loggedInUserId,
          userName: _loggedInUserName,
          userRole: _loggedInUserRole,
        ),
      ];

      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Pesanan'), // Icon beda
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ];

    } else {
      // === LAYOUT USER BIASA ===
      bodyContent = [
        _buildVenueList(),           // Index 0: Home (Tanpa Tombol Tambah)
        HistoryScreen(userName: _loggedInUserName), // Index 1: History Saya
        ProfileScreen(               // Index 2: Profil & Logout
          userId: _loggedInUserId,
          userName: _loggedInUserName,
          userRole: _loggedInUserRole,
        ),
      ];

      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ];
    }

    return Scaffold(
      // Body berubah sesuai Tab yang dipilih
      body: bodyContent.elementAt(_selectedIndex),

      // Navbar Bawah (Selalu muncul untuk Admin & User, tapi isinya beda)
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Biar icon gak goyang kalau > 3
      ),
    );
  }
}