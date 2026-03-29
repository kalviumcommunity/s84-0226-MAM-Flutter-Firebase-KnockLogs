import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, analytics, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Analytics Dashboard',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 24),

              // KPI Cards Row
              _buildKPIGrid(context, analytics),
              const SizedBox(height: 24),

              // Activity Card
              _buildActivityCard(context),
              const SizedBox(height: 24),

              // Weekly Stats Card
              _buildWeeklyStatsCard(context, analytics),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKPIGrid(BuildContext context, AnalyticsProvider analytics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildKPICard(
          context: context,
          title: 'Visitors Today',
          value: '${analytics.visitorsToday}',
          icon: Icons.people,
          color: Colors.blue,
        ),
        _buildKPICard(
          context: context,
          title: 'Approved',
          value: '${analytics.approvedCount}',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _buildKPICard(
          context: context,
          title: 'Pending',
          value: '${analytics.rejectedCount}',
          icon: Icons.pending_actions,
          color: Colors.orange,
        ),
        _buildKPICard(
          context: context,
          title: 'Weekly Avg',
          value: _calculateWeeklyAverage(analytics).toStringAsFixed(1),
          icon: Icons.trending_up,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getRecentActivity(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No recent activity',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                final activities = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    final status = activity['status'] ?? 'Unknown';
                    final name = activity['name'] ?? 'User';
                    final timestamp = activity['timestamp'] ?? 'Just now';

                    IconData icon = Icons.help;
                    Color color = Colors.grey;

                    if (status.contains('in')) {
                      icon = Icons.check_circle;
                      color = Colors.green;
                    } else if (status.contains('out')) {
                      icon = Icons.exit_to_app;
                      color = Colors.red;
                    } else if (status.contains('pending')) {
                      icon = Icons.pending_actions;
                      color = Colors.orange;
                    }

                    return ListTile(
                      leading: Icon(icon, color: color),
                      title: Text(name),
                      subtitle: Text(status),
                      trailing: Text(timestamp),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getRecentActivity() async {
    // This would typically call a service to get real activity data
    // For now, return empty list - can be expanded with real data
    return [];
  }

  Widget _buildWeeklyStatsCard(BuildContext context, AnalyticsProvider analytics) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxValue = analytics.visitorWeek.isEmpty
        ? 100
        : (analytics.visitorWeek.reduce((a, b) => a > b ? a : b) as int).toDouble() + 10;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Visitors',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                days.length,
                (index) {
                  final value = analytics.visitorWeek[index].toDouble();
                  final height = (value / maxValue) * 120;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 30,
                        height: height,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.7),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        days[index],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${analytics.visitorWeek[index]}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Total: ${analytics.visitorWeek.reduce((a, b) => a + b)} visitors',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateWeeklyAverage(AnalyticsProvider analytics) {
    if (analytics.visitorWeek.isEmpty) return 0;
    final sum = analytics.visitorWeek.reduce((a, b) => a + b);
    return sum / analytics.visitorWeek.length;
  }
}
