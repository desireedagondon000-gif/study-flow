import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';
import '../widgets/app_header.dart';
import 'landing_page.dart';
import 'study_planner.dart';
import 'kanban_board.dart';
import 'profile_page.dart';
import '../providers/tasks_provider.dart';

// --- SIDEBAR PROVIDER ---
final sidebarIndexProvider = NotifierProvider<SidebarIndexNotifier, int>(
  SidebarIndexNotifier.new,
);

class SidebarIndexNotifier extends Notifier<int> {
  @override
  int build() {
    _restoreIndex();
    return 0;
  }

  Future<void> _restoreIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('sidebar_index') ?? 0;
    if (ref.mounted) {
      state = savedIndex;
    }
  }

  Future<void> setIndex(int index) async {
    state = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sidebar_index', index);
  }
}

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(sidebarIndexProvider);
    final pages = [
      const DashboardHome(),
      const KanbanBoard(),
      const StudyPlanner(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      appBar: AppHeader(
        actions: _neoButton(
          "LOG OUT",
          () => _handleLogout(context, ref),
          const Color(0xFFFFCDD2),
        ),
      ),
      body: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(width: 3, color: Colors.black)),
            ),
            child: NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (idx) =>
                  ref.read(sidebarIndexProvider.notifier).setIndex(idx),
              backgroundColor: const Color(0xFFFFFDF5),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.view_kanban),
                  label: Text('Kanban'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.book),
                  label: Text('Planner'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
          ),
          Expanded(child: pages[currentIndex]),
        ],
      ),
    );
  }

  Widget _neoButton(String text, VoidCallback onPressed, Color color) =>
      GestureDetector(
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            border: Border.all(width: 3),
            boxShadow: const [BoxShadow(offset: Offset(4, 4))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      );

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingPage()),
        (r) => false,
      );
    }
  }
}

class DashboardHome extends ConsumerWidget {
  const DashboardHome({super.key});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return Colors.green;
      case 'in-progress':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (tasks) {
          final total = tasks.length;
          final completed = tasks.where((t) => t.status == 'done').length;
          final subjects = tasks
              .map((t) => t.subject ?? 'General')
              .toSet()
              .length;
          final progress = total > 0 ? (completed / total) : 0.0;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "DASHBOARD",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        _statCard(
                          "TOTAL TASKS",
                          "$total",
                          Colors.white,
                          ref,
                          1,
                        ),
                        _statCard(
                          "COMPLETED",
                          "$completed",
                          Colors.green[200]!,
                          ref,
                          1,
                        ),
                        _statCard(
                          "SUBJECTS",
                          "$subjects",
                          Colors.blue[100]!,
                          ref,
                          2,
                        ),
                        _scoreCard("COMPLETION", progress, Colors.yellow[200]!),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      "RECENT ACTIVITY",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // RECENT ACTIVITY LIST RESTORED
                    if (tasks.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(border: Border.all(width: 2)),
                        child: const Center(child: Text("No tasks yet.")),
                      )
                    else
                      ...tasks
                          .take(5)
                          .map(
                            (task) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border.all(width: 2),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    color: _getStatusColor(task.status),
                                    child: Text(
                                      task.status.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _scoreCard(String label, double progress, Color color) => Container(
    width: 200,
    height: 160,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      border: Border.all(width: 3),
      boxShadow: const [BoxShadow(offset: Offset(6, 6))],
    ),
    child: Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        CircularPercentIndicator(
          radius: 35.0,
          lineWidth: 8.0,
          percent: progress,
          center: Text(
            "${(progress * 100).round()}%",
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          progressColor: Colors.black,
          backgroundColor: Colors.white54,
        ),
      ],
    ),
  );

  Widget _statCard(
    String label,
    String value,
    Color color,
    WidgetRef ref,
    int targetIndex,
  ) => InkWell(
    onTap: () => ref.read(sidebarIndexProvider.notifier).setIndex(targetIndex),
    child: Container(
      width: 200,
      height: 160,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(width: 3),
        boxShadow: const [BoxShadow(offset: Offset(6, 6))],
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ),
  );
}
