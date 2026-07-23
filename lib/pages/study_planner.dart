import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/tasks_provider.dart';
import '../models/task_model.dart';

// 1. Class to hold the state of each task's timer
class TimerState {
  int secondsRemaining;
  bool isRunning;
  bool isPanelOpen;
  Timer? timer;
  int presetMinutes;
  DateTime? lastSaved;

  TimerState({
    required this.secondsRemaining,
    required this.isRunning,
    required this.isPanelOpen,
    required this.presetMinutes,
    this.timer,
    this.lastSaved,
  });

  Map<String, dynamic> toJson() => {
    'secondsRemaining': secondsRemaining,
    'isRunning': isRunning,
    'isPanelOpen': isPanelOpen,
    'presetMinutes': presetMinutes,
    'lastSaved': lastSaved?.toIso8601String(),
  };

  factory TimerState.fromJson(Map<String, dynamic> json) {
    return TimerState(
      secondsRemaining: json['secondsRemaining'] as int,
      isRunning: json['isRunning'] as bool,
      isPanelOpen: json['isPanelOpen'] as bool,
      presetMinutes: json['presetMinutes'] as int,
      lastSaved: json['lastSaved'] != null
          ? DateTime.parse(json['lastSaved'] as String)
          : null,
    );
  }
}

class StudyPlanner extends ConsumerStatefulWidget {
  const StudyPlanner({super.key});

  @override
  ConsumerState<StudyPlanner> createState() => _StudyPlannerState();
}

class _StudyPlannerState extends ConsumerState<StudyPlanner>
    with WidgetsBindingObserver {
  // 2. Map to store timer state per task ID
  final Map<String, TimerState> _timerStates = {};
  final List<String> _revisionCards = [
    'Summarize key ideas',
    'Practice sample questions',
    'Create quick flashcards',
  ];
  final List<String> _quickNotes = [
    'Highlight definitions',
    'Write one-sentence summary',
    'Add mnemonic hints',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPlannerState();
  }

  @override
  void dispose() {
    for (var state in _timerStates.values) {
      state.timer?.cancel();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _savePlannerState();
    }
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
    final state = _timerStates.putIfAbsent(
      task.id,
      () => TimerState(
        secondsRemaining: 25 * 60,
        isRunning: false,
        isPanelOpen: false,
        presetMinutes: 25,
      ),
    );

    final buttonLabel = state.isPanelOpen
        ? 'LEAVE'
        : state.isRunning
        ? 'OPEN'
        : 'START';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                    onPressed: () => state.isPanelOpen
                        ? _leaveTaskPanel(state)
                        : _openTaskPanel(state),
                    child: Text(buttonLabel),
                  ),
                ],
              ),
              if (state.isPanelOpen) ...[
                const SizedBox(height: 16),
                _buildPomodoroPanel(task, state),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _toggleTaskTimer(Task task, TimerState state) {
    if (state.isRunning) {
      state.timer?.cancel();
      state.isRunning = false;
    } else {
      state.timer?.cancel();
      state.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.secondsRemaining > 0) {
          setState(() => state.secondsRemaining--);
        } else {
          timer.cancel();
          setState(() => state.isRunning = false);
        }
      });
      state.isRunning = true;
    }
    state.lastSaved = DateTime.now();
    setState(() {});
    _savePlannerState();
  }

  void _setPresetForTask(Task task, TimerState state, int minutes) {
    state.timer?.cancel();
    state.timer = null;
    setState(() {
      state.presetMinutes = minutes;
      state.secondsRemaining = minutes * 60;
      state.isRunning = false;
    });
    _savePlannerState();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  void _addRevisionCard() {
    _showNoteEditor(
      title: 'New Revision Card',
      initialValue: '',
      onSubmit: (value) {
        if (value.trim().isEmpty) return;
        setState(() {
          _revisionCards.add(value.trim());
          _savePlannerState();
        });
      },
    );
  }

  void _editRevisionCard(int index) {
    _showNoteEditor(
      title: 'Edit Revision Card',
      initialValue: _revisionCards[index],
      onSubmit: (value) {
        if (value.trim().isEmpty) return;
        setState(() {
          _revisionCards[index] = value.trim();
          _savePlannerState();
        });
      },
    );
  }

  void _deleteRevisionCard(int index) {
    setState(() {
      _revisionCards.removeAt(index);
      _savePlannerState();
    });
  }

  void _addQuickNote() {
    _showNoteEditor(
      title: 'New Quick Note',
      initialValue: '',
      onSubmit: (value) {
        if (value.trim().isEmpty) return;
        setState(() {
          _quickNotes.add(value.trim());
          _savePlannerState();
        });
      },
    );
  }

  void _editQuickNote(int index) {
    _showNoteEditor(
      title: 'Edit Quick Note',
      initialValue: _quickNotes[index],
      onSubmit: (value) {
        if (value.trim().isEmpty) return;
        setState(() {
          _quickNotes[index] = value.trim();
          _savePlannerState();
        });
      },
    );
  }

  void _deleteQuickNote(int index) {
    setState(() {
      _quickNotes.removeAt(index);
      _savePlannerState();
    });
  }

  void _showNoteEditor({
    required String title,
    required String initialValue,
    required void Function(String) onSubmit,
  }) {
    final controller = TextEditingController(text: initialValue);

    showDialog(
      context: context,
      builder: (context) => _buildNoteEditorDialog(
        title: title,
        controller: controller,
        onCancel: () => Navigator.pop(context),
        onSave: () {
          onSubmit(controller.text);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openTaskPanel(TimerState state) {
    setState(() {
      state.isPanelOpen = true;
    });
    _savePlannerState();
  }

  void _leaveTaskPanel(TimerState state) {
    setState(() {
      state.isPanelOpen = false;
    });
    _savePlannerState();
  }

  Future<void> _savePlannerState() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'timerStates': _timerStates.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'revisionCards': _revisionCards,
      'quickNotes': _quickNotes,
    };
    await prefs.setString('study_planner_state', jsonEncode(data));
  }

  Future<void> _loadPlannerState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('study_planner_state');
    if (jsonString == null) return;

    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final timerStatesJson = decoded['timerStates'] as Map<String, dynamic>;

    setState(() {
      _timerStates.clear();
      for (final entry in timerStatesJson.entries) {
        final state = TimerState.fromJson(entry.value as Map<String, dynamic>);
        if (state.isRunning && state.lastSaved != null) {
          final elapsed = DateTime.now().difference(state.lastSaved!).inSeconds;
          state.secondsRemaining = (state.secondsRemaining - elapsed).clamp(
            0,
            state.secondsRemaining,
          );
          if (state.secondsRemaining > 0) {
            state.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (state.secondsRemaining > 0) {
                setState(() => state.secondsRemaining--);
              } else {
                timer.cancel();
                setState(() => state.isRunning = false);
              }
            });
          } else {
            state.isRunning = false;
          }
        }
        _timerStates[entry.key] = state;
      }
      final revisionCards = decoded['revisionCards'] as List<dynamic>?;
      final quickNotes = decoded['quickNotes'] as List<dynamic>?;
      if (revisionCards != null) {
        _revisionCards
          ..clear()
          ..addAll(revisionCards.cast<String>());
      }
      if (quickNotes != null) {
        _quickNotes
          ..clear()
          ..addAll(quickNotes.cast<String>());
      }
    });
  }

  Widget _buildNoteEditorDialog({
    required String title,
    required TextEditingController controller,
    required VoidCallback onCancel,
    required VoidCallback onSave,
  }) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF5),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_note,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 4,
                maxLines: 6,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFFFFDF5),
                  hintText: 'Type your note here...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onSave(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Color(0xFFBDBDBD)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.check),
                      label: const Text('Save note'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPomodoroPanel(Task task, TimerState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F2),
        border: Border.all(color: const Color(0xFFB2DFDB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Focus session for ${task.title}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _formatTime(state.secondsRemaining),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _toggleTaskTimer(task, state),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.isRunning ? Colors.teal : Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: Text(state.isRunning ? 'PAUSE' : 'CONTINUE'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip(task, state, 10),
              _buildPresetChip(task, state, 25),
              _buildPresetChip(task, state, 50),
              _buildPresetChip(task, state, 5),
              _buildPresetChip(task, state, 15),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                'Revision Cards',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: _addRevisionCard,
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.teal[700],
                tooltip: 'Add revision card',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              _revisionCards.length,
              (index) => InputChip(
                label: Text(_revisionCards[index]),
                avatar: const Icon(Icons.book, size: 18),
                onPressed: () => _editRevisionCard(index),
                onDeleted: () => _deleteRevisionCard(index),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                'Quick Notes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: _addQuickNote,
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.teal[700],
                tooltip: 'Add quick note',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              _quickNotes.length,
              (index) => InputChip(
                label: Text(_quickNotes[index]),
                avatar: const Icon(Icons.note, size: 18),
                onPressed: () => _editQuickNote(index),
                onDeleted: () => _deleteQuickNote(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(Task task, TimerState state, int minutes) {
    return OutlinedButton(
      onPressed: () => _setPresetForTask(task, state, minutes),
      child: Text('${minutes}m'),
    );
  }
}
