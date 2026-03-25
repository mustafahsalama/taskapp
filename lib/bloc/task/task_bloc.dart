import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/task.dart';
import '../../data/repositories/task_repository.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _repository;

  TaskBloc({TaskRepository? repository})
      : _repository = repository ?? TaskRepository.instance,
        super(const TaskInitial()) {
    on<TaskLoadRequested>(_onLoadRequested);
    on<TaskAdded>(_onAdded);
    on<TaskUpdated>(_onUpdated);
    on<TaskDeleted>(_onDeleted);
    on<TaskToggleCompleted>(_onToggleCompleted);
    on<TaskCompletedVisibilityToggled>(_onVisibilityToggled);
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  void _onLoadRequested(
      TaskLoadRequested event, Emitter<TaskState> emit) {
    emit(const TaskLoading());
    final result = _repository.getAllTasks();
    result.fold(
      (failure) => emit(TaskFailureState(failure.message)),
      (tasks) => emit(_buildLoaded(List<Task>.from(tasks))),
    );
  }

  Future<void> _onAdded(TaskAdded event, Emitter<TaskState> emit) async {
    final current = state;
    if (current is! TaskLoaded) return;

    // Optimistic update – show immediately.
    final optimisticPending =
        _insertSortedPending(List.from(current.pending), event.task);
    emit(current.copyWith(pending: optimisticPending));

    final result = await _repository.saveTask(event.task);
    result.fold(
      (failure) {
        emit(current); // rollback
        emit(TaskFailureState(failure.message));
      },
      (_) {/* optimistic state is correct — nothing to do */},
    );
  }

  Future<void> _onUpdated(
      TaskUpdated event, Emitter<TaskState> emit) async {
    final current = state;
    if (current is! TaskLoaded) return;

    // Rebuild both lists so sorting is always correct after an edit.
    final allTasks = [
      ...current.pending.map((t) => t.id == event.task.id ? event.task : t),
      ...current.completed.map((t) => t.id == event.task.id ? event.task : t),
    ];
    emit(current.copyWith(
      pending: _sortPending(
          allTasks.where((t) => !t.isCompleted).toList()),
      completed: _sortCompleted(
          allTasks.where((t) => t.isCompleted).toList()),
    ));

    final result = await _repository.saveTask(event.task);
    result.fold(
      (failure) {
        // Rollback to the state before the optimistic update.
        emit(current);
        emit(TaskFailureState(failure.message));
      },
      (_) {},
    );
  }

  Future<void> _onDeleted(
      TaskDeleted event, Emitter<TaskState> emit) async {
    final current = state;
    if (current is! TaskLoaded) return;

    // Optimistic removal.
    emit(current.copyWith(
      pending: current.pending
          .where((t) => t.id != event.task.id)
          .toList(),
      completed: current.completed
          .where((t) => t.id != event.task.id)
          .toList(),
    ));

    final result = await _repository.deleteTask(event.task.id);
    result.fold(
      (failure) {
        emit(current);
        emit(TaskFailureState(failure.message));
      },
      (_) {},
    );
  }

  Future<void> _onToggleCompleted(
      TaskToggleCompleted event, Emitter<TaskState> emit) async {
    final current = state;
    if (current is! TaskLoaded) return;

    final wasCompleted = event.task.isCompleted;
    final updated = event.task.copyWith(
      isCompleted: !wasCompleted,
      completedAt: !wasCompleted ? DateTime.now() : null,
      clearCompletedAt: wasCompleted,
    );

    List<Task> pending = List.from(current.pending);
    List<Task> completed = List.from(current.completed);

    if (wasCompleted) {
      // Moving back to pending.
      completed.removeWhere((t) => t.id == updated.id);
      pending = _insertSortedPending(pending, updated);
    } else {
      // Moving to completed.
      pending.removeWhere((t) => t.id == updated.id);
      completed.insert(0, updated);
    }

    emit(current.copyWith(pending: pending, completed: completed));

    final result = await _repository.saveTask(updated);
    result.fold(
      (failure) {
        emit(current);
        emit(TaskFailureState(failure.message));
      },
      (_) {},
    );
  }

  void _onVisibilityToggled(
      TaskCompletedVisibilityToggled event, Emitter<TaskState> emit) {
    final current = state;
    if (current is! TaskLoaded) return;
    emit(current.copyWith(showCompleted: !current.showCompleted));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  TaskLoaded _buildLoaded(List<Task> tasks, {bool showCompleted = true}) {
    return TaskLoaded(
      pending: _sortPending(tasks.where((t) => !t.isCompleted).toList()),
      completed: _sortCompleted(tasks.where((t) => t.isCompleted).toList()),
      showCompleted: showCompleted,
    );
  }

  List<Task> _sortPending(List<Task> tasks) {
    return tasks
      ..sort((a, b) {
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        }
        if (a.dueDate != null) return -1;
        if (b.dueDate != null) return 1;
        return a.createdAt.compareTo(b.createdAt);
      });
  }

  List<Task> _sortCompleted(List<Task> tasks) {
    return tasks
      ..sort((a, b) {
        final at = a.completedAt ?? a.createdAt;
        final bt = b.completedAt ?? b.createdAt;
        return bt.compareTo(at);
      });
  }

  /// Inserts [task] into [list] at the correct sorted position.
  List<Task> _insertSortedPending(List<Task> list, Task task) {
    final idx = list.indexWhere((t) {
      if (task.dueDate != null && t.dueDate != null) {
        return task.dueDate!.compareTo(t.dueDate!) <= 0;
      }
      if (task.dueDate != null) return true;
      return false;
    });
    list.insert(idx == -1 ? list.length : idx, task);
    return list;
  }
}