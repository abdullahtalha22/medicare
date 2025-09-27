// lib/screens/insights_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _medsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .snapshots();
  }

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text(
          'Health Insights',
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
          builder: (context, medsSnap) {
            if (!medsSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final totalMeds = medsSnap.data!.docs.length;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _logsStream(),
              builder: (context, logsSnap) {
                if (!logsSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final logs = logsSnap.data!.docs;
                final takenCount = logs.length;
                final missedCount =
                totalMeds > takenCount ? totalMeds - takenCount : 0;

                final compliance = totalMeds == 0
                    ? 0.0
                    : (takenCount / totalMeds).clamp(0.0, 1.0);

                // Last 7 days data
                final now = DateTime.now();
                final Map<String, int> takenPerDay = {};

                for (int i = 6; i >= 0; i--) {
                  final date = now.subtract(Duration(days: i));
                  final key = DateFormat('MM/dd').format(date);
                  takenPerDay[key] = 0;
                }

                for (var log in logs) {
                  final ts = log['takenAt'] as Timestamp?;
                  if (ts != null) {
                    final dt = ts.toDate();
                    final key = DateFormat('MM/dd').format(dt);
                    if (takenPerDay.containsKey(key)) {
                      takenPerDay[key] = (takenPerDay[key] ?? 0) + 1;
                    }
                  }
                }

                final spots = takenPerDay.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((e) {
                  final index = e.key.toDouble();
                  final value = e.value.value.toDouble();
                  return FlSpot(index, value);
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 🔹 Summary cards
                    Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            context,
                            title: "Weekly Compliance",
                            value: "${(compliance * 100).round()}%",
                            color: Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _summaryCard(
                            context,
                            title: "Total Medicines",
                            value: "$totalMeds",
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _summaryCard(
                            context,
                            title: "Taken Doses",
                            value: "$takenCount",
                            color: Colors.orangeAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 🔹 Compliance progress bar
                    _glassContainer(
                      context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Compliance',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: compliance,
                            minHeight: 12,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(compliance * 100).round()}% adherence',
                            style: TextStyle(color: textColor.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🔹 Pie Chart
                    _glassContainer(
                      context,
                      child: Column(
                        children: [
                          Text(
                            "Taken vs Missed",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 220,
                            child: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    value: takenCount.toDouble(),
                                    color: Colors.greenAccent,
                                    title: 'Taken',
                                    radius: 60,
                                    titleStyle: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  PieChartSectionData(
                                    value: missedCount.toDouble(),
                                    color: Colors.redAccent,
                                    title: 'Missed',
                                    radius: 60,
                                    titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                                sectionsSpace: 4,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🔹 Line Chart
                    _glassContainer(
                      context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last 7 Days Trend',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 220,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(show: true),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.3)),
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 &&
                                            index < takenPerDay.keys.length) {
                                          return Text(
                                            takenPerDay.keys.elementAt(index),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: true),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spots,
                                    isCurved: true,
                                    barWidth: 3,
                                    color: Colors.greenAccent,
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color:
                                      Colors.greenAccent.withOpacity(0.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // 🔹 Glassmorphism container
  Widget _glassContainer(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  // 🔹 Summary card widget
  Widget _summaryCard(BuildContext context,
      {required String title,
        required String value,
        required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return _glassContainer(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }


}
