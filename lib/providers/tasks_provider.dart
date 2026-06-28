import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';

// This provider automatically streams all tasks for the current user.
// Because we updated Task.fromJson, this stream now automatically
// includes the 'subject' field from Supabase.
final tasksProvider = StreamProvider<List<Task>>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  // Added a check to ensure we only stream tasks for the logged-in user
  return supabase
      .from('tasks')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId ?? '') // Ensures user-specific data
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => Task.fromJson(json)).toList());
});

// Added this provider as discussed for the StudyPlanner filtering
final selectedSubjectProvider = StateProvider<String?>((ref) => null);
