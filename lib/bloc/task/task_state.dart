part of 'task_bloc.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {
  const TaskInitial();
}

class TaskLoading extends TaskState {
  const TaskLoading();
}

class TaskLoaded extends TaskState {
  /// Pending tasks sorted by due date (earliest first), then createdAt.
  final List<Task> pending;

  /// Completed tasks sorted by completedAt descending.
  final List<Task> completed;

  /// Controls visibility of the completed section.
  final bool showCompleted;

  const TaskLoaded({
    required this.pending,
    required this.completed,
    this.showCompleted = true,
  });

  int get totalCount => pending.length + completed.length;

  TaskLoaded copyWith({
    List<Task>? pending,
    List<Task>? completed,
    bool? showCompleted,
  }) {
    return TaskLoaded(
      pending: pending ?? this.pending,
      completed: completed ?? this.completed,
      showCompleted: showCompleted ?? this.showCompleted,
    );
  }

  @override
  List<Object?> get props => [pending, completed, showCompleted];
}

class TaskFailureState extends TaskState {
  final String message;
  const TaskFailureState(this.message);

  @override
  List<Object?> get props => [message];
}