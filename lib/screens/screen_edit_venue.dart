import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Wajib Import
import '../models/venue_model.dart';
import '../services/venue_service.dart';

class ScreenEditVenue extends StatefulWidget {
  final Venue venue;

  const ScreenEditVenue({super.key, required this.venue});

  @override
  State<ScreenEditVenue> createState() => _ScreenEditVenueState();
}

class _ScreenEditVenueState extends State<ScreenEditVenue> {
  final _formKey = GlobalKey<FormState>();
  final VenueService _venueService = VenueService();

  bool _isLoading = false;
  File? _imageFile; // Menyimpan gambar baru jika user mengganti foto
  final ImagePicker _picker = ImagePicker();

  // URL Base Gambar (Sesuaikan dengan port Laravel kamu)
  final String _imageBaseUrl = "http://10.0.2.2:8001/uploads/";

  // Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _capCtrl;

  @override
  void initState() {
    super.initState();
    // 1. ISI FORM DENGAN DATA LAMA
    _nameCtrl = TextEditingController(text: widget.venue.name);
    _descCtrl = TextEditingController(text: widget.venue.description);
    _locCtrl = TextEditingController(text: widget.venue.location);
    _priceCtrl = TextEditingController(text: widget.venue.pricePerHour.toString());
    _capCtrl = TextEditingController(text: widget.venue.capacity.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    _priceCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  // Fungsi Pilih Gambar Baru
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Fungsi Simpan Perubahan
  Future<void> _updateVenue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 2. SIAPKAN DATA BODY (Map<String, String>)
      // Sesuai dengan parameter saveVenueMultipart di service kamu
      Map<String, String> body = {
        'name': _nameCtrl.text,
        'description': _descCtrl.text,
        'location': _locCtrl.text,
        'price_per_hour': _priceCtrl.text,
        'capacity': _capCtrl.text,
        // Kirim facilities hardcode dulu (atau buat inputan khusus jika mau)
        'facilities[]': "AC",
      };

      // 3. PANGGIL SERVICE (saveVenueMultipart)
      // ID dikirim agar service tahu ini adalah UPDATE (PUT)
      bool success = await _venueService.saveVenueMultipart(
          body,
          _imageFile, // File gambar baru (bisa null jika tidak ganti)
          widget.venue.id // ID Gedung lama
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gedung berhasil diperbarui!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Kembali ke Home
        }
      } else {
        throw Exception("Gagal update data");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Gedung")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- AREA GAMBAR ---
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover) // Tampilkan gambar baru yg dipilih
                        : (widget.venue.images.isNotEmpty
                        ? Image.network(
                      // Tampilkan gambar lama dari server
                      widget.venue.images.first.startsWith('http')
                          ? widget.venue.images.first
                          : "$_imageBaseUrl${widget.venue.images.first}",
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50),
                    )
                        : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Icon(Icons.camera_alt, size: 50), Text("Tap ganti foto")],
                    )),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(child: Text("Ketuk gambar untuk mengganti foto", style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 20),

              // --- FORM INPUT ---
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Nama Gedung", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locCtrl,
                decoration: const InputDecoration(labelText: "Lokasi", border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: "Deskripsi", border: OutlineInputBorder()),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Harga/Jam", border: OutlineInputBorder(), prefixText: "Rp "),
                      validator: (val) => val!.isEmpty ? "Wajib isi" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _capCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Kapasitas", border: OutlineInputBorder(), suffixText: "Orang"),
                      validator: (val) => val!.isEmpty ? "Wajib isi" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- TOMBOL UPDATE ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isLoading ? null : _updateVenue,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("UPDATE GEDUNG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}