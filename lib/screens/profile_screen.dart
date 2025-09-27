import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool _loading = true;
  bool _isEditing = false;
  File? _profileImage;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await userDoc.get();

    if (doc.exists) {
      final data = doc.data()!;
      _nameCtrl.text = data['name'] ?? '';
      _phoneCtrl.text = data['phone'] ?? '';
      _addressCtrl.text = data['address'] ?? '';
    } else {
      await userDoc.set({
        'email': FirebaseAuth.instance.currentUser?.email,
        'name': '',
        'phone': '',
        'address': '',
      });
    }

    // Load local image path
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString("profile_image");
    if (path != null && File(path).existsSync()) {
      _profileImage = File(path);
    }

    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': _nameCtrl.text,
      'phone': _phoneCtrl.text,
      'address': _addressCtrl.text,
      'email': FirebaseAuth.instance.currentUser?.email,
    }, SetOptions(merge: true));

    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated ✅")),
    );
  }

  Future<void> _logout() async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Sign out from Google if logged in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Clear saved credentials for auto-login
      await _secureStorage.delete(key: 'remember');
      await _secureStorage.delete(key: 'email');
      await _secureStorage.delete(key: 'password');

      // Navigate to LoginScreen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: $e")),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    final imageFile = File(picked.path);

    // Save path locally for other screens
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("profile_image", imageFile.path);

    setState(() {
      _profileImage = imageFile;
    });
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a Photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.white), // always white
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0f8b8e), Color(0xFF2a86d6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.2)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isEditing ? _showImagePickerOptions : null,
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.blueAccent,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? Text(
                        (user?.email ?? "U")
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _nameCtrl.text.isEmpty
                        ? (user?.email ?? "User")
                        : _nameCtrl.text,
                    style: const TextStyle( // always white for dark/light
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Stay on track with your medicines 💊",
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Editable Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: "Name",
                      labelStyle: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                    v == null || v.isEmpty ? "Enter name" : null,
                    style:
                    TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: "Phone",
                      labelStyle: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      border: const OutlineInputBorder(),
                    ),
                    style:
                    TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtrl,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: "Address",
                      labelStyle: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      border: const OutlineInputBorder(),
                    ),
                    style:
                    TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 20),
                  if (_isEditing)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 24),
                      ),
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        "Save Profile",
                        style:
                        TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.green),
              title: const Text("Settings"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Logout"),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}
