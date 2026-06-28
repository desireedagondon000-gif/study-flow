import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tasks_provider.dart';
import '../models/task_model.dart';
import 'task_editor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KanbanBoard extends ConsumerWidget {
  const KanbanBoard({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'todo':
        return const Color(0xFFFFD1DC); // Pastel Pink
      case 'in_progress':
        return const Color(0xFFFFF5BA); // Pastel Yellow
      case 'done':
        return const Color(0xFFB9FBC0); // Pastel Green
      default:
        return const Color(0xFFE0E0E0); // Default Gray
    }
  }

  Future<void> _deleteTask(
    BuildContext context,
    String taskId,
    WidgetRef ref,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "DELETE TASK",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text("Are you sure you want to delete this task?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client.from('tasks').delete().eq('id', taskId);
        ref.invalidate(tasksProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error deleting: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TaskEditor()),
          );
          ref.invalidate(tasksProvider);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (tasks) {
          // Wrap in a horizontal scroll view to prevent overflow
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildColumn(
                  context,
                  "To Do",
                  tasks.where((t) => t.status == 'todo').toList(),
                  ref,
                ),
                _buildColumn(
                  context,
                  "In Progress",
                  tasks.where((t) => t.status == 'in_progress').toList(),
                  ref,
                ),
                _buildColumn(
                  context,
                  "Done",
                  tasks.where((t) => t.status == 'done').toList(),
                  ref,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildColumn(
    BuildContext context,
    String title,
    List<Task> tasks,
    WidgetRef ref,
  ) {
    // Set a fixed width for columns so they don't squish
    return SizedBox(
      width: 280,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const Divider(color: Colors.black, thickness: 2),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true, // Allows ListView to fit inside the column
                itemCount: tasks.length,
                itemBuilder: (context, index) =>
                    _buildTaskCard(context, tasks[index], ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(task.status),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject Badge
          if (task.subject != null && task.subject!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                border: Border.all(color: Colors.black),
              ),
              child: Text(
                task.subject!.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (task.description != null && task.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                task.description!,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TaskEditor(task: task)),
                  );
                  ref.invalidate(tasksProvider);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                onPressed: () => _deleteTask(context, task.id, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
