import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'add_medicine_screen.dart';
import 'schedule_screen.dart';
import 'logs_screen.dart';
import 'insights_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _headerFadeController;
  String? _displayName;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _headerFadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _headerFadeController.forward();
    _loadUserName();
    _loadProfileImage();
  }

  Future<void> _loadUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (mounted) {
      setState(() {
        _displayName = userDoc.data()?['name'] ??
            FirebaseAuth.instance.currentUser?.email ??
            'User';
      });
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString("profile_image");
    if (path != null && File(path).existsSync()) {
      setState(() {
        _profileImage = File(path);
      });
    }
  }

  @override
  void dispose() {
    _headerFadeController.dispose();
    super.dispose();
  }

  TextStyle _headingStyle(BuildContext ctx) =>
      Theme.of(ctx).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold);

  TextStyle _smallStyle(BuildContext ctx) =>
      Theme.of(ctx).textTheme.bodyMedium!.copyWith(
        color: Theme.of(ctx).brightness == Brightness.dark
            ? Colors.white70
            : Colors.black54,
      );

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeBody(),
      const ScheduleScreen(),
      const InsightsScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home, color: Colors.blue), label: "Home"),
          NavigationDestination(
              icon: Icon(Icons.calendar_today, color: Colors.green),
              label: "Schedule"),
          NavigationDestination(
              icon: Icon(Icons.show_chart, color: Colors.purple),
              label: "Insights"),
          NavigationDestination(
              icon: Icon(Icons.person, color: Colors.orange),
              label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildHomeBody() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return SafeArea(
        child: Center(child: Text('Please login to see your medicines.')),
      );
    }

    final medsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .where('status', isEqualTo: 'upcoming')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: CurvedAnimation(
                    parent: _headerFadeController, curve: Curves.easeOut),
                child: _buildHeader(),
              ),
              const SizedBox(height: 18),
              Text('Quick Actions', style: _headingStyle(context)),
              const SizedBox(height: 12),
              _buildActionGrid(),
              const SizedBox(height: 18),
              Text('Upcoming Medicines', style: _headingStyle(context)),
              const SizedBox(height: 12),
              SizedBox(
                height: 190,
                child: StreamBuilder<QuerySnapshot>(
                  stream: medsStream,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(
                          child: Text('Error: ${snap.error}',
                              style: _smallStyle(context)));
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      return Center(
                          child: Text('No upcoming medicines',
                              style: _smallStyle(context)));
                    }
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, idx) {
                        final data = docs[idx].data() as Map<String, dynamic>;
                        return _MedicineCard(
                          docId: docs[idx].id,
                          name: data['name'] ?? 'Unknown',
                          time: data['time'] ?? '--:--',
                          dosage: data['dosage'] ?? '',
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final displayName =
        _displayName ?? FirebaseAuth.instance.currentUser?.email ?? 'User';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 18, offset: Offset(0, 8))
        ],
      ),
      child: Row(children: [
        SizedBox(
            width: 84,
            height: 84,
            child: Lottie.asset('assets/animations/home_header.json',
                fit: BoxFit.contain)),
        const SizedBox(width: 12),
        Expanded(
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Good Day 👋',
                style:
                _smallStyle(context).copyWith(color: Colors.blueAccent)),
            const SizedBox(height: 4),
            Text(displayName,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text("Let's keep your health on track today.",
                style: _smallStyle(context)),
          ]),
        ),
        InkWell(
          onTap: () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
            _loadUserName();
            _loadProfileImage();
          },
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary,
            backgroundImage:
            _profileImage != null ? FileImage(_profileImage!) : null,
            child: _profileImage == null
                ? Text(
              displayName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            )
                : null,
          ),
        )
      ]),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.12,
      children: [
        _glassAction(
            title: 'Add Medicine',
            lottieAsset: 'assets/animations/card_pill.json',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddMedicineScreen()))),
        _glassAction(
            title: 'View Schedule',
            lottieAsset: 'assets/animations/card_calendar.json',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ScheduleScreen()))),
        _glassAction(
            title: 'Prescription Logs',
            lottieAsset: 'assets/animations/card_logs.json',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LogsScreen()))),
        _glassAction(
            title: 'Health Insights',
            lottieAsset: 'assets/animations/card_insights.json',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const InsightsScreen()))),
      ],
    );
  }

  Widget _glassAction(
      {required String title,
        required String lottieAsset,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.4),
                Colors.white.withOpacity(0.2)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Lottie.asset(lottieAsset, repeat: true)),
            const SizedBox(height: 6),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
          ],
        ),
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  final String docId;
  final String name;
  final String time;
  final String dosage;

  const _MedicineCard({
    required this.docId,
    required this.name,
    required this.time,
    required this.dosage,
  });

  Future<void> _markAsTaken(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .doc(docId);
    await docRef.update({
      'status': 'taken',
      'takenAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine marked as taken ✅')));
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87);

    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
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
          BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          Icon(
            MdiIcons.pill,
            color: Colors.redAccent,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(dosage, style: TextStyle(color: textColor.withOpacity(0.8))),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.access_time,
                    size: 16, color: textColor.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(time, style: TextStyle(color: textColor.withOpacity(0.9)))
              ]),
              ElevatedButton(
                onPressed: () => _markAsTaken(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Take', style: TextStyle(color: Colors.white)),
              )
            ],
          )
        ],
      ),
    );
  }
}
