import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db_services.dart';
import '../models/update_log.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  bool isLoading = true;
  int totalLogs = 0;
  int totalProducts = 0;
  int successCount = 0;
  int failedCount = 0;
  String topCategory = "-";
  List<UpdateLogSummary> allLogs = [];

  // Theme colors
  static const Color kBg = Color(0xFFFDF6F2);
  static const Color kPrimary = Color(0xFFD7A4A4);
  static const Color kText = Color(0xFF3E3E3E);
  static const Color kCard = Color(0xFFFFFFFF);
  static const Color kGold = Color(0xFFE8C547);
  static const Color kLavender = Color(0xFFE3D0D8);

  @override
  void initState() {
    super.initState();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    setState(() => isLoading = true);
    try {
      allLogs = await DBService.getSummaryLogs();
      totalLogs = allLogs.length;
      totalProducts = allLogs.fold(0, (sum, log) => sum + log.total);
      successCount = allLogs.fold(0, (sum, log) => sum + log.success);
      failedCount = allLogs.fold(0, (sum, log) => sum + log.failed);

      // Find top category
      final categoryCount = <String, int>{};
      for (var log in allLogs) {
        categoryCount[log.category] =
            (categoryCount[log.category] ?? 0) + log.total;
      }
      if (categoryCount.isNotEmpty) {
        topCategory = categoryCount.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }
    } catch (e) {
      debugPrint("⚠️ Analytics load error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 4,
        centerTitle: true,
        title: const Text(
          "📊 Analytics Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              color: kPrimary,
              onRefresh: loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatCards(),
                    const SizedBox(height: 20),
                    _buildPieChart(),
                    const SizedBox(height: 20),
                    _buildTopCategoryCard(),
                    const SizedBox(height: 20),
                    _buildRecentActivityList(),
                  ],
                ),
              ),
            ),
    );
  }

  // 🔹 Summary Cards (Total Logs, Products, Success)
  Widget _buildStatCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statCard("Total Logs", totalLogs.toString(), Icons.list_alt, kPrimary),
        _statCard("Products", totalProducts.toString(),
            Icons.shopping_bag_outlined, kGold),
        _statCard("Success", successCount.toString(),
            Icons.check_circle_rounded, Colors.green),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        color: kCard,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        shadowColor: Colors.black12,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Pie Chart (Success vs Failed)
  Widget _buildPieChart() {
    final int total = successCount + failedCount;
    double successPercent = 0;
    double failedPercent = 0;

    if (total > 0) {
      successPercent = (successCount / total) * 100;
      failedPercent = (failedCount / total) * 100;
    }

    return Card(
      color: kCard,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Success vs Failed Updates",
              style: TextStyle(
                color: kText,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: Colors.green.withOpacity(0.8),
                      value: successPercent,
                      title: "${successPercent.toStringAsFixed(1)}%",
                      radius: 55,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.redAccent.withOpacity(0.8),
                      value: failedPercent,
                      title: "${failedPercent.toStringAsFixed(1)}%",
                      radius: 50,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _LegendItem(color: Colors.green, label: "Success"),
                SizedBox(width: 15),
                _LegendItem(color: Colors.redAccent, label: "Failed"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Top Category
  Widget _buildTopCategoryCard() {
    return Card(
      color: kCard,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.star_rounded, color: kGold, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Top Updated Category: $topCategory",
                style: const TextStyle(
                  color: kText,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Recent Updates
  Widget _buildRecentActivityList() {
    final recentLogs = allLogs.take(5).toList();
    if (recentLogs.isEmpty) {
      return const Text(
        "No recent updates found.",
        style: TextStyle(color: Colors.grey),
      );
    }

    return Card(
      color: kCard,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🕒 Recent Updates",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: kText,
                fontSize: 15,
              ),
            ),
            const Divider(),
            ...recentLogs.map((log) => ListTile(
                  leading: Icon(
                    log.operation == "Increase"
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: log.operation == "Increase"
                        ? Colors.green
                        : Colors.redAccent,
                  ),
                  title: Text(
                    "${log.category} - ${log.subCategory ?? "-"}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kText,
                    ),
                  ),
                  subtitle: Text(
                    "${log.operation} ${log.valueType} ${log.value} | ${DateFormat('dd MMM, hh:mm a').format(log.timestamp)}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}

