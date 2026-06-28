import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tasks_provider.dart';
import '../models/task_model.dart';

// 1. Class to hold the state of each task's timer
class TimerState {
  int secondsRemaining;
  bool isRunning;
  bool hasStarted;
  Timer? timer;
  int presetMinutes;

  TimerState({
    required this.secondsRemaining,
    required this.isRunning,
    required this.hasStarted,
    required this.presetMinutes,
    this.timer,
  });
}

class StudyPlanner extends ConsumerStatefulWidget {
  const StudyPlanner({super.key});

  @override
  ConsumerState<StudyPlanner> createState() => _StudyPlannerState();
}

class _StudyPlannerState extends ConsumerState<StudyPlanner> {
  // 2. Map to store timer state per task ID
  final Map<String, TimerState> _timerStates = {};

  @override
  void dispose() {
    for (var state in _timerStates.values) {
      state.timer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final selectedSubject = ref.watch(selectedSubjectProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text("Error: $err")),
          data: (tasks) {
            final activeTasks = tasks.where((t) => t.status != 'done').toList();
            final subjects = activeTasks
                .map((t) => t.subject ?? 'General')
                .toSet()
                .toList();

            final filteredTasks = selectedSubject == null
                ? activeTasks
                : activeTasks
                      .where((t) => (t.subject ?? 'General') == selectedSubject)
                      .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "STUDY SESSIONS",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  children: [
                    FilterChip(
                      label: const Text("ALL"),
                      selected: selectedSubject == null,
                      onSelected: (_) =>
                          ref.read(selectedSubjectProvider.notifier).state =
                              null,
                    ),
                    ...subjects.map(
                      (s) => FilterChip(
                        label: Text(s.toUpperCase()),
                        selected: selectedSubject == s,
                        onSelected: (_) =>
                            ref.read(selectedSubjectProvider.notifier).state =
                                s,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) =>
                        _buildStudyCard(filteredTasks[index], context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStudyCard(Task task, BuildContext context) {
    return Center(
      // 1. Center the card to prevent it from stretching
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
        ), // 2. Set a maximum width
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [
              BoxShadow(offset: Offset(4, 4), color: Colors.black),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.subject?.toUpperCase() ?? "GENERAL",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16), // Add a little spacing
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(),
                ),
                onPressed: () => _showPomodoroDialog(context, task),
                child: const Text("START"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPomodoroDialog(BuildContext context, Task task) {
    // Get existing state or create new one
    final state = _timerStates.putIfAbsent(
      task.id,
      () => TimerState(
        secondsRemaining: 25 * 60,
        isRunning: false,
        hasStarted: false,
        presetMinutes: 25,
      ),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void toggleTimer() {
            if (state.isRunning) {
              state.timer?.cancel();
            } else {
              state.hasStarted = true;
              state.timer = Timer.periodic(const Duration(seconds: 1), (t) {
                if (state.secondsRemaining > 0) {
                  setState(() => state.secondsRemaining--);
                  setDialogState(() {});
                } else {
                  t.cancel();
                  state.isRunning = false;
                  setDialogState(() {});
                }
              });
            }
            setState(() => state.isRunning = !state.isRunning);
            setDialogState(() {});
          }

          void stopTimer() {
            state.timer?.cancel();
            setState(() {
              state.timer = null;
              state.secondsRemaining = state.presetMinutes * 60;
              state.isRunning = false;
              state.hasStarted = false;
            });
            setDialogState(() {});
          }

          void setPreset(int minutes) {
            state.timer?.cancel();
            setState(() {
              state.timer = null;
              state.presetMinutes = minutes;
              state.secondsRemaining = minutes * 60;
              state.isRunning = false;
              state.hasStarted = false;
            });
            setDialogState(() {});
          }

          String formatTime(int s) {
            int m = s ~/ 60;
            int sec = s % 60;
            return "${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
          }

          return AlertDialog(
            title: Text("FOCUS: ${task.title.toUpperCase()}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatTime(state.secondsRemaining),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: toggleTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.isRunning
                            ? Colors.orange
                            : Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        state.isRunning
                            ? "PAUSE"
                            : (state.hasStarted ? "CONTINUE" : "START"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: stopTimer,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text("STOP"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => setPreset(25),
                      child: const Text("25m"),
                    ),
                    OutlinedButton(
                      onPressed: () => setPreset(5),
                      child: const Text("5m"),
                    ),
                    OutlinedButton(
                      onPressed: () => setPreset(15),
                      child: const Text("15m"),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CLOSE"),
              ),
            ],
          );
        },
      ),
    );
  }
}
