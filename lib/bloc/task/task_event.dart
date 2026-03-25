part of 'task_bloc.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers the initial load of all tasks from the repository.
class TaskLoadRequested extends TaskEvent {
  const TaskLoadRequested();
}

/// Persists a newly created task.
class TaskAdded extends TaskEvent {
  final Task task;
  const TaskAdded(this.task);

  @override
  List<Object?> get props => [task];
}

/// Persists an edited task (same id, updated fields).
class TaskUpdated extends TaskEvent {
  final Task task;
  const TaskUpdated(this.task);

  @override
  List<Object?> get props => [task];
}

/// Deletes a task by id.
class TaskDeleted extends TaskEvent {
  final Task task;
  const TaskDeleted(this.task);

  @override
  List<Object?> get props => [task];
}

/// Toggles the completion status of a task.
class TaskToggleCompleted extends TaskEvent {
  final Task task;
  const TaskToggleCompleted(this.task);

  @override
  List<Object?> get props => [task];
}

/// Shows or hides the completed-tasks section.
class TaskCompletedVisibilityToggled extends TaskEvent {
  const TaskCompletedVisibilityToggled();
}