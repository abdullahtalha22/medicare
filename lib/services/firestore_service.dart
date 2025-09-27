// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> seedMedicines() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final medsRef = _db.collection("users").doc(uid).collection("medicines");

    final existing = await medsRef.limit(1).get();
    if (existing.docs.isNotEmpty) return; // already seeded

    final demoMeds = [
      {
        "name": "Paracetamol",
        "dose": "500mg",
        "time": "08:00 AM",
        "notes": "For fever",
      },
      {
        "name": "Amoxicillin",
        "dose": "250mg",
        "time": "12:00 PM",
        "notes": "After meal",
      },
      {
        "name": "Ibuprofen",
        "dose": "200mg",
        "time": "04:00 PM",
        "notes": "For headache",
      },
      {
        "name": "Vitamin C",
        "dose": "1000mg",
        "time": "06:00 PM",
        "notes": "Boost immunity",
      },
      {
        "name": "Metformin",
        "dose": "500mg",
        "time": "09:00 PM",
        "notes": "For diabetes",
      },
    ];

    for (var med in demoMeds) {
      await medsRef.add({
        ...med,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }
}
