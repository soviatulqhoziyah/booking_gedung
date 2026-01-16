import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String userRole;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userRole,
  });

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus semua sesi
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false, // Hapus semua stack navigasi ke belakang
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar Profil
      appBar: AppBar(title: const Text("Profil Saya"), automaticallyImplyLeading: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.teal,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Chip(
                label: Text(userRole.toUpperCase()),
                backgroundColor: userRole == 'admin' ? Colors.orange.shade100 : Colors.blue.shade100,
              ),
              const SizedBox(height: 40),

              // Info Tambahan
              ListTile(
                leading: const Icon(Icons.key),
                title: const Text("User ID"),
                subtitle: Text(userId),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),

              const Spacer(),

              // TOMBOL LOGOUT
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text("KELUAR APLIKASI"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}