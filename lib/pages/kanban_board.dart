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

  Future<void> _updateTaskStatus(
    BuildContext context,
    Task task,
    String newStatus,
    WidgetRef ref,
  ) async {
    if (task.status == newStatus) return;

    try {
      await Supabase.instance.client
          .from('tasks')
          .update({'status': newStatus})
          .eq('id', task.id);
      ref.invalidate(tasksProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Moved "${task.title}" to ${newStatus.replaceAll('_', ' ')}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error updating task: $e")));
      }
    }
  }

  String _statusFromTitle(String title) {
    switch (title.toLowerCase()) {
      case 'to do':
        return 'todo';
      case 'in progress':
        return 'in_progress';
      case 'done':
        return 'done';
      default:
        return 'todo';
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
          return LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 760;
              final columns = [
                _buildColumn(
                  context,
                  "To Do",
                  tasks.where((t) => t.status == 'todo').toList(),
                  ref,
                  isNarrow,
                ),
                _buildColumn(
                  context,
                  "In Progress",
                  tasks.where((t) => t.status == 'in_progress').toList(),
                  ref,
                  isNarrow,
                ),
                _buildColumn(
                  context,
                  "Done",
                  tasks.where((t) => t.status == 'done').toList(),
                  ref,
                  isNarrow,
                ),
              ];

              if (isNarrow) {
                return ListView(
                  padding: const EdgeInsets.all(8),
                  children: columns,
                );
              }

              return Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: columns
                      .map((column) => Expanded(child: column))
                      .toList(),
                ),
              );
            },
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
    bool isNarrow,
  ) {
    final status = _statusFromTitle(title);

    final content = DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) =>
          _updateTaskStatus(context, details.data, status, ref),
      builder: (context, candidateData, rejectedData) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            border: candidateData.isNotEmpty
                ? Border.all(color: Colors.blue, width: 2)
                : null,
          ),
          child: tasks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Drag tasks here',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: isNarrow,
                  physics: isNarrow
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) =>
                      _buildTaskCard(context, tasks[index], ref),
                ),
        );
      },
    );

    return Container(
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
          if (isNarrow) content else Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task, WidgetRef ref) {
    return Draggable<Task>(
      data: task,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        elevation: 8,
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: _buildTaskCardContent(context, task, ref, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildTaskCardContent(context, task, ref),
      ),
      child: _buildTaskCardContent(context, task, ref),
    );
  }

  Widget _buildTaskCardContent(
    BuildContext context,
    Task task,
    WidgetRef ref, {
    bool isDragging = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(task.status),
        border: Border.all(color: Colors.black),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                tooltip: 'Edit task',
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
