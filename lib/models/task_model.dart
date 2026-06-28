class Task {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String status;
  final String? subject; // Added subject field
  final DateTime? dueDate;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.status,
    this.subject, // Included in constructor
    this.dueDate,
    required this.createdAt,
  });

  // Convert JSON from Supabase into a Task object
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      subject: json['subject'], // Added mapping
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Convert a Task object into JSON to send to Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'status': status,
      'subject': subject, // Added mapping
      'due_date': dueDate?.toIso8601String(),
    };
  }
}
