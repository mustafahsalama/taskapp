import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Color _dueDateColor(DateTime due) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final d =
        DateTime(due.year, due.month, due.day);
    if (d.isBefore(today)) return Colors.red.shade600;
    if (d.isAtSameMomentAs(today)) return Colors.orange.shade600;
    if (d.difference(today).inDays == 1) return Colors.amber.shade700;
    return Colors.green.shade600;
  }

  String _dueDateLabel(DateTime due) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final d = DateTime(due.year, due.month, due.day);
    if (d.isBefore(today)) {
      final diff = today.difference(d).inDays;
      return diff == 1 ? 'Yesterday' : '$diff days overdue';
    }
    if (d.isAtSameMomentAs(today)) return 'Today';
    if (d.difference(today).inDays == 1) return 'Tomorrow';
    return DateFormat('MMM d').format(due);
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Dismissible(
            key: ValueKey('dismiss_${task.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delete_outline,
                  color: Colors.white, size: 28),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Task'),
                  content:
                      Text('Delete "${task.title}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Delete',
                          style:
                              TextStyle(color: Colors.red.shade600)),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (_) => widget.onDelete(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? Colors.grey.shade50
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(
                    color: task.isCompleted
                        ? Colors.green.shade400
                        : cs.primary,
                    width: 4,
                  ),
                ),
                boxShadow: task.isCompleted
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: InkWell(
                onTap: widget.onEdit,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Checkbox(
                        isCompleted: task.isCompleted,
                        onTap: widget.onToggle,
                        activeColor: cs.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style: tt.bodyMedium!.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: task.isCompleted
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade800,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: Colors.grey.shade400,
                              ),
                              child: Text(
                                task.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (task.description.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 250),
                                style: tt.bodySmall!.copyWith(
                                  color: task.isCompleted
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade500,
                                ),
                                child: Text(
                                  task.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 4,
                              children: [
                                _Chip(
                                  icon: Icons.calendar_today_outlined,
                                  label: DateFormat('MMM d, y')
                                      .format(task.createdAt),
                                  color: Colors.grey.shade400,
                                ),
                                if (task.dueDate != null &&
                                    !task.isCompleted)
                                  _Chip(
                                    icon: Icons.flag_outlined,
                                    label: _dueDateLabel(task.dueDate!),
                                    color: _dueDateColor(task.dueDate!),
                                  ),
                                if (task.isCompleted &&
                                    task.completedAt != null)
                                  _Chip(
                                    icon: Icons.check_circle_outline,
                                    label:
                                        'Done ${DateFormat('MMM d').format(task.completedAt!)}',
                                    color: Colors.green.shade500,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: Colors.grey.shade300, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Checkbox extends StatefulWidget {
  final bool isCompleted;
  final VoidCallback onTap;
  final Color activeColor;

  const _Checkbox({
    required this.isCompleted,
    required this.onTap,
    required this.activeColor,
  });

  @override
  State<_Checkbox> createState() => _CheckboxState();
}

class _CheckboxState extends State<_Checkbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.isCompleted ? 1.0 : 0.0,
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(_Checkbox old) {
    super.didUpdateWidget(old);
    if (widget.isCompleted != old.isCompleted) {
      if (widget.isCompleted) {
        _ctrl.forward(from: 0.0);
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 24,
        height: 24,
        margin: const EdgeInsets.only(top: 1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isCompleted
              ? Colors.green.shade500
              : Colors.transparent,
          border: Border.all(
            color: widget.isCompleted
                ? Colors.green.shade500
                : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: widget.isCompleted
            ? ScaleTransition(
                scale: _scaleAnim,
                child: const Icon(Icons.check,
                    color: Colors.white, size: 14),
              )
            : null,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}