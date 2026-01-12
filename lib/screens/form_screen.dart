import 'dart:convert'; // Untuk encode gambar ke Base64
import 'dart:io';      // Untuk mengatur File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Wajib install plugin ini
import '../models/venue_model.dart';
import '../services/venue_service.dart';

class FormScreen extends StatefulWidget {
  final Venue? venue; // Jika null = Mode Tambah, Jika ada isi = Mode Edit

  const FormScreen({super.key, this.venue});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final VenueService _apiService = VenueService();

  // Status loading saat tombol ditekan
  bool _isLoading = false;

  // Controller untuk input text
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _capacityController;

  // Variabel untuk menyimpan file foto yang diambil
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Helper untuk cek mode edit atau tambah
  bool get isEditMode => widget.venue != null;

  @override
  void initState() {
    super.initState();
    // Isi data awal jika sedang dalam Mode Edit
    _nameController = TextEditingController(text: isEditMode ? widget.venue!.name : '');
    _descController = TextEditingController(text: isEditMode ? widget.venue!.description : '');
    _locationController = TextEditingController(text: isEditMode ? widget.venue!.location : '');
    _priceController = TextEditingController(text: isEditMode ? widget.venue!.pricePerHour.toString() : '');
    _capacityController = TextEditingController(text: isEditMode ? widget.venue!.capacity.toString() : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  // --- FITUR 1: MENAMPILKAN POPUP PILIHAN (KAMERA / GALERI) ---
  void _showImagePickerOption(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (builder) {
        return Padding(
          padding: const EdgeInsets.all(18.0),
          child: SizedBox(
            height: 120, // Tinggi kotak dialog
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickImageFromSource(ImageSource.gallery),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library, size: 50, color: Colors.teal),
                        Text("Galeri", style: TextStyle(fontWeight: FontWeight.bold))
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickImageFromSource(ImageSource.camera),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 50, color: Colors.orange),
                        Text("Kamera", style: TextStyle(fontWeight: FontWeight.bold))
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- FITUR 2: LOGIKA PROSES AMBIL GAMBAR ---
  Future<void> _pickImageFromSource(ImageSource source) async {
    Navigator.pop(context); // Tutup dialog pilihan dulu

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source, // Sesuai pilihan user (Kamera/Galeri)
        maxWidth: 800,  // Kompres lebar gambar biar ringan
        imageQuality: 80, // Kompres kualitas JPG ke 80%
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error ambil gambar: $e");
    }
  }

  // --- FITUR 3: UBAH GAMBAR JADI TEXT (BASE64) ---
  String? _imageToBase64(File? imageFile) {
    if (imageFile == null) return null;
    List<int> imageBytes = imageFile.readAsBytesSync();
    String base64Image = base64Encode(imageBytes);
    // Tambahkan header agar server tahu ini gambar JPG
    return "data:image/jpeg;base64,$base64Image";
  }

  // --- FITUR 4: KIRIM DATA KE BACKEND ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Siapkan List Foto
    List<String> imageList = [];

    // Logika pengiriman foto:
    // 1. Jika user baru saja ambil foto, pakai foto itu (convert ke Base64)
    if (_selectedImage != null) {
      String? base64String = _imageToBase64(_selectedImage);
      if (base64String != null) imageList.add(base64String);
    }
    // 2. Jika Mode Edit dan user TIDAK ganti foto, pakai foto lama yang ada di database
    else if (isEditMode && widget.venue!.images.isNotEmpty) {
      imageList = widget.venue!.images;
    }
    // 3. Jika kosong melompong (jarang terjadi), kasih placeholder
    else {
      imageList.add("https://via.placeholder.com/150");
    }

    // Bungkus data dalam Model Venue
    final venueData = Venue(
      id: isEditMode ? widget.venue!.id : null,
      name: _nameController.text,
      description: _descController.text,
      location: _locationController.text,
      pricePerHour: int.parse(_priceController.text),
      capacity: int.parse(_capacityController.text),
      facilities: ["AC", "WiFi", "Sound System"], // Bisa dikembangkan jadi checkbox nanti
      images: imageList,
    );

    // Kirim ke Service
    bool success;
    if (isEditMode) {
      success = await _apiService.updateVenue(venueData);
    } else {
      success = await _apiService.createVenue(venueData);
    }

    setState(() => _isLoading = false);

    // Cek Hasil
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil disimpan!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Kembali ke halaman sebelumnya
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan data'), backgroundColor: Colors.red),
      );
    }
  }

  // --- UI DESIGN ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Edit Gedung' : 'Tambah Gedung')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- KOTAK FOTO ---
              GestureDetector(
                onTap: () => _showImagePickerOption(context), // Panggil Popup
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                    image: _selectedImage != null
                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                        : null, // Jika belum ada foto baru, kosongkan background image
                  ),
                  child: _selectedImage == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          isEditMode ? Icons.edit : Icons.add_a_photo,
                          size: 50,
                          color: Colors.grey.shade600
                      ),
                      const SizedBox(height: 8),
                      Text(
                          isEditMode ? "Ketuk untuk ganti foto" : "Ketuk untuk ambil foto",
                          style: TextStyle(color: Colors.grey.shade600)
                      ),
                    ],
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // --- FORM INPUT ---
              _buildTextField(_nameController, 'Nama Gedung', Icons.business),
              const SizedBox(height: 16),
              _buildTextField(_locationController, 'Lokasi', Icons.location_on),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_priceController, 'Harga (Rp)', Icons.attach_money, isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_capacityController, 'Kapasitas', Icons.people, isNumber: true)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(_descController, 'Deskripsi Lengkap', Icons.description, maxLines: 3),
              const SizedBox(height: 24),

              // --- TOMBOL SIMPAN ---
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : Text(
                    isEditMode ? 'UPDATE DATA' : 'SIMPAN DATA',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget kecil agar kodingan rapi
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      validator: (val) => val == null || val.isEmpty ? '$label wajib diisi' : null,
    );
  }
}