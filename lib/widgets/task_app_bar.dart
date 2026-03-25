import 'package:flutter/material.dart';

class TaskAppBar extends StatelessWidget {
  const TaskAppBar({super.key,
    required this.cs,
    required this.total,
    required this.pending,
  });

  final ColorScheme cs;
  final int total;
  final int pending;

  static const _titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 26,
    fontWeight: FontWeight.bold,
  );

  static const _subtitleStyle = TextStyle(
    color: Colors.white70,
    fontSize: 14,
  );

  static const _collapsedTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  String get _subtitle {
    if (total == 0) return 'No tasks yet';
    final taskWord = total == 1 ? 'task' : 'tasks';
    return '$total $taskWord · $pending pending';
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(

      expandedHeight: 130,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: cs.primary,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        titlePadding: const EdgeInsetsDirectional.only(
          start: 20,
          bottom: 14,
        ),
        title: const Text('Task Manager', style: _collapsedTitleStyle),
        background: _AppBarBackground(cs: cs, subtitle: _subtitle),
      ),
    );
  }
}

class _AppBarBackground extends StatelessWidget {
  const _AppBarBackground({
    required this.cs,
    required this.subtitle,
  });

  final ColorScheme cs;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              //const Text('Task Manager', style: TaskAppBar._titleStyle),
              const SizedBox(height: 20),
              Text(subtitle, style: TaskAppBar._subtitleStyle),
            ],
          ),
        ),
      ),
    );
  }
}