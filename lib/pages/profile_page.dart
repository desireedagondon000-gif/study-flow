import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_flow/providers/tasks_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  static const _prefIconKey = 'profile_icon_index';

  // Default icon
  IconData selectedIcon = Icons.person;

  // List of available icons for the user to choose
  final List<IconData> iconOptions = [
    Icons.person,
    Icons.school,
    Icons.star,
    Icons.rocket,
    Icons.emoji_objects,
    Icons.favorite,
    Icons.computer,
    Icons.palette,
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedIcon();
  }

  Future<void> _loadSelectedIcon() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(_prefIconKey) ?? 0;
    if (savedIndex >= 0 && savedIndex < iconOptions.length) {
      setState(() {
        selectedIcon = iconOptions[savedIndex];
      });
    }
  }

  Future<void> _saveSelectedIcon(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefIconKey, index);
  }

  void _showIconPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choose Avatar"),
        content: SizedBox(
          width: 300,
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: iconOptions.length,
            itemBuilder: (context, index) => IconButton(
              icon: Icon(iconOptions[index], size: 30),
              onPressed: () {
                setState(() => selectedIcon = iconOptions[index]);
                _saveSelectedIcon(index);
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final String joinDate = user?.createdAt != null
        ? user!.createdAt.substring(0, 10)
        : 'Recently';

    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      body: Center(
        child: tasksAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, _) => Text("Error: $err"),
          data: (tasks) {
            final totalTasks = tasks.length;
            final subjectCount = tasks
                .map((t) => t.subject ?? 'General')
                .toSet()
                .length;

            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildInfoCard(
                    child: Column(
                      children: [
                        // Clickable Icon instead of Random Image
                        InkWell(
                          onTap: () => _showIconPicker(context),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border.all(width: 2),
                              boxShadow: const [
                                BoxShadow(offset: Offset(4, 4)),
                              ],
                            ),
                            child: Center(child: Icon(selectedIcon, size: 50)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          user?.email ?? 'No Email',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Member since: $joinDate",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatContainer(
                          "SUBJECTS",
                          "$subjectCount",
                          const Color(0xFFFFF59D),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatContainer(
                          "TASKS",
                          "$totalTasks",
                          const Color(0xFFFFD1DC),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(width: 2),
      boxShadow: const [BoxShadow(offset: Offset(4, 4))],
    ),
    child: child,
  );

  Widget _buildStatContainer(String label, String value, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(width: 2),
          boxShadow: const [BoxShadow(offset: Offset(4, 4))],
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
}
