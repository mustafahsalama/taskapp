import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  DateTime? _dueDate;
  bool get _isEditing => widget.task != null;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task?.title ?? '');
    _descCtrl = TextEditingController(text: widget.task?.description ?? '');
    _dueDate = widget.task?.dueDate;

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final task = _isEditing
        ? widget.task!.copyWith(
            title: title,
            description: _descCtrl.text.trim(),
            dueDate: _dueDate,
            clearDueDate: _dueDate == null,
          )
        : Task(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            description: _descCtrl.text.trim(),
            createdAt: DateTime.now(),
            dueDate: _dueDate,
          );

    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Task' : 'New Task',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check, color: Colors.white, size: 20),
              label: const Text('Save',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Task Title *'),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleCtrl,
                  autofocus: !_isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration(
                    hint: 'What do you need to do?',
                    icon: Icons.title,
                  ),
                ),
                const SizedBox(height: 20),
                _sectionLabel('Description'),
                const SizedBox(height: 8),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                    hint: 'Add details (optional)...',
                    icon: Icons.notes,
                  ),
                ),
                const SizedBox(height: 20),
                _sectionLabel('Due Date'),
                const SizedBox(height: 8),
                _DueDatePicker(
                  dueDate: _dueDate,
                  onTap: _pickDate,
                  onClear: () => setState(() => _dueDate = null),
                  primaryColor: cs.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.3,
        ),
      );

  InputDecoration _inputDecoration(
          {required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      );
}

class _DueDatePicker extends StatelessWidget {
  final DateTime? dueDate;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final Color primaryColor;

  const _DueDatePicker({
    required this.dueDate,
    required this.onTap,
    required this.onClear,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: dueDate != null ? primaryColor : Colors.grey.shade300,
            width: dueDate != null ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: dueDate != null
              ? primaryColor.withValues(alpha: 0.04)
              : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(
              dueDate != null
                  ? Icons.flag
                  : Icons.flag_outlined,
              color: dueDate != null ? primaryColor : Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Due Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dueDate != null
                        ? DateFormat('EEEE, MMMM d, y').format(dueDate!)
                        : 'Tap to set a due date',
                    style: TextStyle(
                      fontSize: 14,
                      color: dueDate != null
                          ? Colors.grey.shade800
                          : Colors.grey.shade400,
                      fontWeight: dueDate != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (dueDate != null)
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close,
                      size: 14, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}