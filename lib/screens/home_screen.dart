import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskapp/widgets/task_app_bar.dart';

import '../bloc/task/task_bloc.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ── Navigation helpers ────────────────────────────────────────────────────

  Future<void> _openAddForm(BuildContext context) async {
    final task = await Navigator.push<Task>(
      context,
      PageRouteBuilder(
        fullscreenDialog: true,
        pageBuilder: (_, anim, __) => const TaskFormScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
    if (task == null) return;
    if (!context.mounted) return;
    context.read<TaskBloc>().add(TaskAdded(task));
  }

  Future<void> _openEditForm(BuildContext context, Task task) async {
    final updated = await Navigator.push<Task>(
      context,
      PageRouteBuilder(
        fullscreenDialog: true,
        pageBuilder: (_, anim, __) => TaskFormScreen(task: task),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
    if (updated == null) return;
    if (!context.mounted) return;
    context.read<TaskBloc>().add(TaskUpdated(updated));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskFailureState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final cs = Theme.of(context).colorScheme;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FC),
          body: switch (state) {
            TaskInitial() || TaskLoading() => _buildLoader(cs),
            TaskLoaded() => _buildContent(context, state, cs),
            _ => const SizedBox.shrink(),
          },
          floatingActionButton: _AnimatedFab(
            onPressed: () => _openAddForm(context),
          ),
        );
      },
    );
  }

  // ── State views ───────────────────────────────────────────────────────────

  Widget _buildLoader(ColorScheme cs) {
    return CustomScrollView(
      slivers: [

        TaskAppBar(cs: cs, total: 0, pending: 0),
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  Widget _buildContent(
      BuildContext context, TaskLoaded state, ColorScheme cs) {
    final isEmpty = state.totalCount == 0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [

        TaskAppBar(cs: cs,total: state.totalCount,pending: state.pending.length),
        if (isEmpty)
          _emptyState()
        else ...[
          if (state.pending.isNotEmpty) ...[
            _sectionHeader(
              icon: Icons.radio_button_unchecked,
              title: 'PENDING',
              count: state.pending.length,
              color: cs.primary,
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final task = state.pending[i];
                  return TaskTile(
                    key: ValueKey('p_${task.id}'),
                    task: task,
                    onToggle: () => context
                        .read<TaskBloc>()
                        .add(TaskToggleCompleted(task)),
                    onEdit: () => _openEditForm(context, task),
                    onDelete: () =>
                        context.read<TaskBloc>().add(TaskDeleted(task)),
                  );
                },
                childCount: state.pending.length,
              ),
            ),
          ],
          if (state.completed.isNotEmpty) ...[
            _completedHeader(context, state, cs),
            if (state.showCompleted)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final task = state.completed[i];
                    return TaskTile(
                      key: ValueKey('c_${task.id}'),
                      task: task,
                      onToggle: () => context
                          .read<TaskBloc>()
                          .add(TaskToggleCompleted(task)),
                      onEdit: () => _openEditForm(context, task),
                      onDelete: () =>
                          context.read<TaskBloc>().add(TaskDeleted(task)),
                    );
                  },
                  childCount: state.completed.length,
                ),
              ),
          ],
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // ── Sliver widgets ────────────────────────────────────────────────────────



  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _completedHeader(
      BuildContext context, TaskLoaded state, ColorScheme cs) {
    final color = Colors.green.shade600;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              'COMPLETED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.completed.length}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context
                  .read<TaskBloc>()
                  .add(const TaskCompletedVisibilityToggled()),
              child: AnimatedRotation(
                turns: state.showCompleted ? 0 : 0.5,
                duration: const Duration(milliseconds: 250),
                child:
                    Icon(Icons.expand_less, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (_, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: Icon(Icons.task_alt,
                  size: 90, color: Colors.grey.shade300),
            ),
            const SizedBox(height: 20),
            Text(
              'No tasks yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + below to add your first task',
              style:
                  TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FAB with entry animation ──────────────────────────────────────────────

class _AnimatedFab extends StatefulWidget {
  final VoidCallback onPressed;
  const _AnimatedFab({required this.onPressed});

  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
      child: FloatingActionButton.extended(
        onPressed: widget.onPressed,
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Task',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 4,
      ),
    );
  }
}