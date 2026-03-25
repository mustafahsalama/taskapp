import 'package:dartz/dartz.dart' hide Task;
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/error/failures.dart';
import '../../models/task.dart';

class TaskRepository {
  TaskRepository._();
  static final TaskRepository instance = TaskRepository._();

  Box<Task> get _box => Hive.box<Task>('tasks');

  // ── Read ──────────────────────────────────────────────────────────────────

  Either<Failure, List<Task>> getAllTasks() {
    try {
      return Right(_box.values.toList());
    } catch (e) {
      return Left(HiveFailure('Failed to load tasks: $e'));
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<Either<Failure, Unit>> saveTask(Task task) async {
    try {
      await _box.put(task.id, task);
      return const Right(unit);
    } catch (e) {
      return Left(HiveFailure('Failed to save task: $e'));
    }
  }

  Future<Either<Failure, Unit>> deleteTask(String id) async {
    try {
      await _box.delete(id);
      return const Right(unit);
    } catch (e) {
      return Left(HiveFailure('Failed to delete task: $e'));
    }
  }
}