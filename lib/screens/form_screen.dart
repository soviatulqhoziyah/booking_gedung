import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/venue_model.dart';
import '../services/venue_service.dart';


class FormScreen extends StatefulWidget {
  final Venue? venue;

  const FormScreen({super.key, this.venue});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final VenueService _apiService = VenueService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _capacityController;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool get isEditMode => widget.venue != null;

  @override
  void initState() {
    super.initState();
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

  void _showImagePickerOption(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (builder) {
        return Padding(
          padding: const EdgeInsets.all(18.0),
          child: SizedBox(
            height: 120,
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

  Future<void> _pickImageFromSource(ImageSource source) async {
    Navigator.pop(context);
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080, // Resolusi lebih baik untuk simpan file
        imageQuality: 70,
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

  // --- PROSES SIMPAN DATA (MULTIPART) ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Persiapkan data teks
    Map<String, String> body = {
      'name': _nameController.text,
      'description': _descController.text,
      'location': _locationController.text,
      'price_per_hour': _priceController.text,
      'capacity': _capacityController.text,
      'facilities[0]': 'WiFi', // Contoh kirim array ke Laravel
      'facilities[1]': 'AC',
    };

    // Jika Mode Edit, Laravel butuh Spoofing Method PUT jika mengirim Multipart
    if (isEditMode) {
      body['_method'] = 'PUT';
    }

    // Panggil Service Multipart
    bool success = await _apiService.saveVenueMultipart(
        body,
        _selectedImage,
        isEditMode ? widget.venue!.id : null
    );

    setState(() => _isLoading = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil disimpan!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan data ke server'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Gedung' : 'Tambah Gedung'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // PREVIEW GAMBAR
              GestureDetector(
                onTap: () => _showImagePickerOption(context),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    image: _selectedImage != null
                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                        : (isEditMode && widget.venue!.images.isNotEmpty
                        ? DecorationImage(
                        image: NetworkImage(widget.venue!.images.first),
                        fit: BoxFit.cover
                    )
                        : null),
                  ),
                  child: _selectedImage == null && (!isEditMode || widget.venue!.images.isEmpty)
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                      Text("Tambah Foto Gedung", style: TextStyle(color: Colors.grey)),
                    ],
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 25),
              _buildTextField(_nameController, 'Nama Gedung', Icons.business),
              const SizedBox(height: 15),
              _buildTextField(_locationController, 'Lokasi', Icons.location_on),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildTextField(_priceController, 'Harga / Jam', Icons.payments, isNumber: true)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildTextField(_capacityController, 'Kapasitas', Icons.people, isNumber: true)),
                ],
              ),
              const SizedBox(height: 15),
              _buildTextField(_descController, 'Deskripsi Lengkap', Icons.description, maxLines: 4),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEditMode ? "UPDATE DATA" : "SIMPAN DATA",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (val) => val == null || val.isEmpty ? 'Field ini tidak boleh kosong' : null,
    );
  }
}