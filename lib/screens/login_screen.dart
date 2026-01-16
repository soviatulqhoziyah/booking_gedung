import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ WAJIB IMPORT
import '../services/user_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  // ✅ Constructor pakai const agar file sebelah tidak merah
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  void _doLogin() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Password wajib diisi")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await UserService().login(_emailCtrl.text, _passCtrl.text);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Proses login selesai")),
        );
      }

      if (result['statusCode'] == 200) {
        print("✅ Login Berhasil! Menyimpan sesi...");

        SharedPreferences prefs = await SharedPreferences.getInstance();
        final rawData = result['data'];

        String userId = "";
        String userName = "User";

        // --- PERBAIKAN LOGIC (LEBIH AMAN) ---
        if (rawData is Map) {
          // Kita pakai 'dynamic' biar tidak merah
          dynamic userObj;

          if (rawData.containsKey('user')) {
            userObj = rawData['user'];
          } else {
            userObj = rawData;
          }

          // Ambil data dengan aman (cek null)
          if (userObj is Map) {
            userId = (userObj['_id'] ?? userObj['id'] ?? "").toString();
            userName = (userObj['username'] ?? userObj['name'] ?? "User").toString();
          }
        }

        // Simpan
        await prefs.setString('userId', userId);
        await prefs.setString('userName', userName);
        await prefs.setBool('isLogin', true);

        print("💾 Berhasil simpan: ID=$userId, Nama=$userName");

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Pemanis
            const Icon(Icons.account_circle, size: 80, color: Colors.teal),
            const SizedBox(height: 20),

            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 25),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _doLogin,
              child: const Text("LOGIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: const Text("Belum punya akun? Daftar di sini"),
            )
          ],
        ),
      ),
    );
  }
}