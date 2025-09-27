// lib/screens/schedule_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _medsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .snapshots();
  }

  Future<void> _deleteMedicine(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text(
          'Schedule',
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
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _medsStream(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'No medicines added yet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              );
            }

            // Prepare & sort
            final items =
            docs.map((d) => {'id': d.id, 'data': d.data()}).toList();

            int getHour(Map<String, dynamic> d) {
              final h = d['timeHour'];
              if (h is int) return h;
              if (h is String) return int.tryParse(h) ?? 24;
              return 24;
            }

            int getMinute(Map<String, dynamic> d) {
              final m = d['timeMinute'];
              if (m is int) return m;
              if (m is String) return int.tryParse(m) ?? 0;
              return 0;
            }

            items.sort((a, b) {
              final ad = a['data'] as Map<String, dynamic>;
              final bd = b['data'] as Map<String, dynamic>;
              final ah = getHour(ad);
              final bh = getHour(bd);
              final am = getMinute(ad);
              final bm = getMinute(bd);
              return (ah * 60 + am).compareTo(bh * 60 + bm);
            });

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final item = items[idx];
                final id = item['id'] as String;
                final data = item['data'] as Map<String, dynamic>;

                final name = data['name'] ?? 'Unnamed';
                final dosage = data['dosage'] ?? '';
                final time = data['time'] ?? '--:--';
                final frequency = data['frequency'] ?? 'Daily';
                final status = data['status'] ?? 'upcoming';

                final isTaken = status.toLowerCase() == 'taken';

                return Dismissible(
                  key: Key(id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteMedicine(id),
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Container(
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
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
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
                          radius: 28,
                          backgroundColor: isTaken
                              ? Colors.green.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.2),
                          child: Icon(
                            MdiIcons.pill,
                            color: isTaken ? Colors.green : Colors.blue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              const SizedBox(height: 2),
                              Text(
                                'Frequency: $frequency',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isTaken
                                ? Colors.green.withOpacity(0.15)
                                : Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isTaken ? 'Taken' : 'Upcoming',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isTaken ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
