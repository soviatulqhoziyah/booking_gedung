import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// IMPORT MODELS & SERVICES
import '../models/ModelReview.dart';
import '../models/venue_model.dart';
import '../services/user_service.dart';
import '../services/venue_service.dart';
import '../services/review_service.dart';

import 'form_screen.dart';
import 'booking_screen.dart';

class DetailScreen extends StatefulWidget {
  final Venue venue;
  final String currentUserId; // ✅ ID User tipe String

  const DetailScreen({
    super.key,
    required this.venue,
    required this.currentUserId
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final VenueService _venueService = VenueService();
  final ReviewService _reviewService = ReviewService();
  final UserService _userService = UserService(); // Untuk ambil nama

  late Future<List<ModelReview>> _reviewsFuture;
  final String _imageBaseUrl = "http://10.0.2.2:8001/uploads/";

  @override
  void initState() {
    super.initState();
    _refreshReviews();
  }

  void _refreshReviews() {
    setState(() {
      _reviewsFuture = _reviewService.getReviews(widget.venue.id!);
    });
  }

  String formatRupiah(int price) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  // --- LOGIKA GAMBAR HEADER ---
  Widget _buildHeaderImage() {
    if (widget.venue.images.isEmpty) return Container(color: Colors.teal);

    String imageName = widget.venue.images.first;
    String finalUrl = imageName.startsWith('http') ? imageName : "$_imageBaseUrl$imageName";

    return Image.network(
      finalUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.teal,
        child: const Center(child: Icon(Icons.broken_image, color: Colors.white70, size: 50)),
      ),
    );
  }

  // --- HAPUS GEDUNG ---
  Future<void> _deleteVenue(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Gedung?"),
        content: const Text("Data ini akan dihapus permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _venueService.deleteVenue(widget.venue.id!);
      if (success && context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  // --- POPUP REVIEW ---
  void _showAddReviewDialog() {
    final commentController = TextEditingController();
    int selectedRating = 5;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Center(child: Text("Beri Penilaian")),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () => setDialogState(() => selectedRating = index + 1),
                        icon: Icon(index < selectedRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  Text("$selectedRating / 5", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(labelText: "Ceritakan pengalamanmu...", border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () async {
                    Navigator.pop(context);
                    // Post Review dengan ID String
                    bool success = await _reviewService.postReview(
                      widget.venue.id!,
                      widget.currentUserId, // String ID
                      selectedRating,
                      commentController.text,
                    );
                    if (success) {
                      _refreshReviews();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ulasan terkirim!"), backgroundColor: Colors.green));
                    }
                  },
                  child: const Text("Kirim"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.venue.name, style: const TextStyle(color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildHeaderImage(),
                  Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)], stops: const [0.6, 1.0]))),
                ],
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => FormScreen(venue: widget.venue)))),
              IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteVenue(context)),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(formatRupiah(widget.venue.pricePerHour), style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.teal, fontWeight: FontWeight.bold)),
                    Chip(label: Text("${widget.venue.capacity} Orang"), avatar: const Icon(Icons.people)),
                  ]),
                  const SizedBox(height: 16),
                  const Row(children: [Icon(Icons.location_on, color: Colors.grey), SizedBox(width: 8), Text("Lokasi", style: TextStyle(fontWeight: FontWeight.bold))]),
                  Text(widget.venue.location, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  const Text("Deskripsi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.venue.description, style: const TextStyle(fontSize: 16, height: 1.5)),
                  const Divider(height: 40, thickness: 2),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text("Ulasan Pengunjung", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    OutlinedButton.icon(onPressed: _showAddReviewDialog, icon: const Icon(Icons.star, size: 16), label: const Text("Beri Nilai"), style: OutlinedButton.styleFrom(foregroundColor: Colors.teal))
                  ]),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // --- LIST REVIEW ---
          FutureBuilder<List<ModelReview>>(
            future: _reviewsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator())));
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text("Belum ada ulasan.", style: TextStyle(color: Colors.grey)))));

              final reviews = snapshot.data!;
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final review = reviews[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: Card(
                        elevation: 0, color: Colors.grey.shade50,
                        shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.teal.shade50, child: Text("${review.rating}", style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold))),
                          title: Row(children: List.generate(5, (i) => Icon(i < review.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 16))),
                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const SizedBox(height: 6), Text(review.comment), const SizedBox(height: 8),
                            // FETCH USERNAME
                            FutureBuilder<String>(
                                future: _userService.getUserName(review.userId), // Kirim String ID
                                builder: (context, userSnapshot) {
                                  String name = userSnapshot.data ?? "User #${review.userId.substring(0,4)}...";
                                  if (userSnapshot.connectionState == ConnectionState.waiting) name = "...";
                                  return Row(children: [const Icon(Icons.person, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal))]);
                                }
                            )
                          ]),
                        ),
                      ),
                    );
                  },
                  childCount: reviews.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BookingPage(idGedung: widget.venue.id!, namaGedung: widget.venue.name, hargaPerJam: widget.venue.pricePerHour.toDouble()))),
          child: const Text("BOOKING SEKARANG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}