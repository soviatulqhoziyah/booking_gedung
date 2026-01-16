
import 'package:flutter/material.dart';
import '../models/ModelUser.dart';
import '../services/user_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _hpCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();

  bool _isLoading = false;

  void _doRegister() async {
    // Validasi input kosong
    if (_userCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty ||
        _hpCtrl.text.isEmpty || _alamatCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Semua field wajib diisi!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. Masukkan data ke Model Datum
    // Secara default role tidak dikirim karena Backend akan otomatis set ke 'user'
    Datum userBaru = Datum(
      username: _userCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
      noHp: _hpCtrl.text,
      alamat: _alamatCtrl.text,
      role: "user", // Kamu bisa kirim ini atau biarkan backend yang handle default-nya
    );

    // 2. Kirim ke API melalui Service
    final result = await UserService().register(userBaru);

    setState(() => _isLoading = false);

    // 3. Munculkan feedback (SnackBar)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? "Proses Selesai")),
    );

    // 4. LOGIKA PINDAH OTOMATIS KE LOGIN
    // Mengecek statusCode yang kita tambahkan di UserService sebelumnya
    if (result['statusCode'] == 200 || result['statusCode'] == 201) {

      print("Registrasi Berhasil. Role: ${result['data']['role']}");

      // Kasih jeda 1.5 detik supaya SnackBar sempat terbaca
      await Future.delayed(Duration(milliseconds: 1500));

      if (mounted) {
        // Pindah ke Login dan hapus semua history page sebelumnya
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Daftar Akun Baru"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _userCtrl, decoration: InputDecoration(labelText: "Username", prefixIcon: Icon(Icons.person))),
            SizedBox(height: 10),
            TextField(controller: _emailCtrl, decoration: InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email))),
            SizedBox(height: 10),
            TextField(controller: _passCtrl, decoration: InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock)), obscureText: true),
            SizedBox(height: 10),
            TextField(controller: _hpCtrl, decoration: InputDecoration(labelText: "No HP", prefixIcon: Icon(Icons.phone))),
            SizedBox(height: 10),
            TextField(controller: _alamatCtrl, decoration: InputDecoration(labelText: "Alamat", prefixIcon: Icon(Icons.location_on))),
            SizedBox(height: 30),

            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: Size.fromHeight(50),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                onPressed: _doRegister,
                child: Text("Register Sekarang", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            ),

            SizedBox(height: 15),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Sudah punya akun? Login di sini")
            )
          ],
        ),
      ),
    );
  }
}
