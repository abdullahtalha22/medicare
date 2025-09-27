// lib/screens/logs_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String _filter = "All";

  Stream<QuerySnapshot<Map<String, dynamic>>> _logsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .where('status', isEqualTo: 'taken')
        .orderBy('takenAt', descending: true)
        .snapshots();
  }

  Future<void> _deleteLog(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .doc(docId)
        .delete();
  }

  String _groupByDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDate = DateTime(dt.year, dt.month, dt.day);

    if (logDate == today) return "Today";
    if (logDate == yesterday) return "Yesterday";
    return DateFormat('MMMM dd, yyyy').format(dt);
  }

  bool _applyFilter(DateTime dt) {
    if (_filter == "All") return true;
    final now = DateTime.now();
    if (_filter == "Today") {
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    }
    if (_filter == "Last 7 Days") {
      return dt.isAfter(now.subtract(const Duration(days: 7)));
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text(
          'Prescription Logs',
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
        child: Column(
          children: [
            // 🔄 Filter buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(10),
                isSelected: ["All", "Today", "Last 7 Days"]
                    .map((f) => _filter == f)
                    .toList(),
                onPressed: (index) {
                  setState(() {
                    _filter = ["All", "Today", "Last 7 Days"][index];
                  });
                },
                fillColor: Colors.teal,
                selectedColor: Colors.white,
                color: isDark ? Colors.white : Colors.black,
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("All"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("Today"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("Last 7 Days"),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _logsStream(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: Text('Error: ${snap.error}',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color)),
                    );
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return Center(
                      child: Text('No logs yet',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color,
                              fontSize: 16)),
                    );
                  }

                  // Group logs by date
                  final grouped = <String,
                      List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
                  for (var doc in docs) {
                    final data = doc.data();
                    final ts = data['takenAt'] as Timestamp?;
                    if (ts == null) continue;
                    final dt = ts.toDate();
                    if (!_applyFilter(dt)) continue;

                    final dateKey = _groupByDate(dt);
                    grouped.putIfAbsent(dateKey, () => []).add(doc);
                  }

                  if (grouped.isEmpty) {
                    return Center(
                      child: Text('No logs for $_filter',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color,
                              fontSize: 16)),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: grouped.entries.map((entry) {
                      final date = entry.key;
                      final items = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...items.map((doc) {
                            final data = doc.data();
                            final id = doc.id;
                            final name = data['name'] ?? 'Unnamed';
                            final dosage = data['dosage'] ?? '';
                            final takenAt =
                            (data['takenAt'] as Timestamp?)?.toDate();
                            final time = takenAt != null
                                ? DateFormat('hh:mm a').format(takenAt)
                                : "--:--";

                            return Dismissible(
                              key: Key(id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _deleteLog(id),
                              background: Container(
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                                alignment: Alignment.centerRight,
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
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
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.3)),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 14,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor:
                                      Colors.green.withOpacity(0.2),
                                      child: Icon(MdiIcons.pill,
                                          color: Colors.green, size: 26),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$dosage • $time',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color
                                                  ?.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Taken',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 20),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
