import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  TimeOfDay? _time;
  String _frequency = 'Daily';
  bool _isLoading = false;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reminder time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not signed in');

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('medicines')
          .add({
        'userId': uid,
        'name': _nameCtrl.text.trim(),
        'dosage': _dosageCtrl.text.trim(),
        'time': _time!.format(context),
        'timeHour': _time!.hour,
        'timeMinute': _time!.minute,
        'frequency': _frequency,
        'status': 'upcoming',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine added successfully ✅')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firestore error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(
      String label, IconData icon, Color iconColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : Colors.black87;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: labelColor),
      prefixIcon: Icon(icon, color: iconColor),
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white24 : Colors.black26,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: iconColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,

      appBar: AppBar(
        title: const Text(
          'Add Medicine',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0f8b8e), Color(0xFF2a86d6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Medicine Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Blur-like card (same style as HomeScreen glass cards)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        style: TextStyle(color: textColor),
                        decoration: _inputDecoration(
                            'Medicine Name', MdiIcons.pill, Colors.teal),
                        validator: (v) =>
                        v == null || v.isEmpty ? 'Enter medicine name' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _dosageCtrl,
                        style: TextStyle(color: textColor),
                        decoration: _inputDecoration(
                            'Dosage (e.g. 500 mg)',
                            MdiIcons.medicalBag,
                            Colors.deepOrange),
                        validator: (v) =>
                        v == null || v.isEmpty ? 'Enter dosage' : null,
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.teal),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _time?.format(context) ??
                                      'Select reminder time',
                                  style: TextStyle(
                                    color: _time == null
                                        ? Colors.grey
                                        : textColor,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _frequency,
                        dropdownColor: isDark ? Colors.black87 : Colors.white,
                        style: TextStyle(color: textColor),
                        decoration: _inputDecoration(
                            'Frequency', MdiIcons.repeat, Colors.purple),
                        items: const [
                          DropdownMenuItem(
                              value: 'Daily',
                              child: Text('Daily')),
                          DropdownMenuItem(
                              value: 'Weekly',
                              child: Text('Weekly')),
                          DropdownMenuItem(
                              value: 'Custom',
                              child: Text('Custom')),
                        ],
                        onChanged: (v) =>
                            setState(() => _frequency = v ?? 'Daily'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // Replace your current SizedBox/ElevatedButton with this
                SizedBox(
                  width: double.infinity,
                  child: InkWell(
                    onTap: _isLoading ? null : _saveMedicine,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0f8b8e), Color(0xFF2a86d6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                          : const Text(
                        'Save Medicine',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
