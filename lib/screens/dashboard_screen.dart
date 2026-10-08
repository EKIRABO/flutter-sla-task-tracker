import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_bottom_navigation.dart';
import 'task_list_screen.dart';

enum _SlaStatus { onTrack, atRisk, overdue, completed }

class _DashboardTask {
  const _DashboardTask({
    required this.title,
    required this.assignee,
    required this.deadline,
    required this.status,
  });

  final String title;
  final String assignee;
  final String deadline;
  final _SlaStatus status;
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.userName});

  final String userName;

  static const List<_DashboardTask> _tasks = [
    _DashboardTask(
      title: 'Design Login Screen',
      assignee: 'Esther',
      deadline: 'Oct 8',
      status: _SlaStatus.atRisk,
    ),
    _DashboardTask(
      title: 'Set Up Database',
      assignee: 'Bior',
      deadline: 'Oct 10',
      status: _SlaStatus.onTrack,
    ),
    _DashboardTask(
      title: 'Fix Navigation Bug',
      assignee: 'Kenia',
      deadline: 'Oct 5',
      status: _SlaStatus.overdue,
    ),
    _DashboardTask(
      title: 'Create Dashboard',
      assignee: 'Gael',
      deadline: 'Oct 7',
      status: _SlaStatus.completed,
    ),
  ];

  int _countStatus(_SlaStatus status) =>
      _tasks.where((task) => task.status == status).length;

  double get _completion =>
      _countStatus(_SlaStatus.completed) / _tasks.length;

  void _onNavigationSelected(BuildContext context, int index) {
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const TaskListScreen(),
        ),
      );
      return;
    }

    if (index > 1) {
      final section = index == 2 ? 'Team' : 'Profile';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('$section screen is not connected yet.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final attentionTasks = _tasks
        .where(
          (task) =>
              task.status == _SlaStatus.atRisk ||
              task.status == _SlaStatus.overdue,
        )
        .toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROJECT WORKSPACE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.mutedText,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hi, $userName',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  foregroundColor: AppColors.primary,
                  child: Text(
                    _initials(userName),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _ProjectProgressCard(
              completed: _countStatus(_SlaStatus.completed),
              total: _tasks.length,
              progress: _completion,
            ),
            const SizedBox(height: 24),
            Text(
              'SLA overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SlaSummaryCard(
                  label: 'On Track',
                  count: _countStatus(_SlaStatus.onTrack),
                  color: AppColors.onTrack,
                  icon: Icons.check_circle_outline_rounded,
                ),
                _SlaSummaryCard(
                  label: 'At Risk',
                  count: _countStatus(_SlaStatus.atRisk),
                  color: AppColors.atRisk,
                  icon: Icons.warning_amber_rounded,
                ),
                _SlaSummaryCard(
                  label: 'Overdue',
                  count: _countStatus(_SlaStatus.overdue),
                  color: AppColors.overdue,
                  icon: Icons.error_outline_rounded,
                ),
                _SlaSummaryCard(
                  label: 'Completed',
                  count: _countStatus(_SlaStatus.completed),
                  color: AppColors.completed,
                  icon: Icons.task_alt_rounded,
                ),
              ],
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Needs attention',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${attentionTasks.length} tasks',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (attentionTasks.isEmpty)
              const _NoAttentionCard()
            else
              ...attentionTasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AttentionTaskCard(task: task),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 0,
        onDestinationSelected: (index) =>
            _onNavigationSelected(context, index),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _ProjectProgressCard extends StatelessWidget {
  const _ProjectProgressCard({
    required this.completed,
    required this.total,
    required this.progress,
  });

  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Project progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF9BE0C0),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$completed of $total tasks completed',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlaSummaryCard extends StatelessWidget {
  const _SlaSummaryCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 52) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 21),
              const SizedBox(height: 12),
              Text(
                '$count',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 24,
                      color: AppColors.text,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttentionTaskCard extends StatelessWidget {
  const _AttentionTaskCard({required this.task});

  final _DashboardTask task;

  @override
  Widget build(BuildContext context) {
    final color = task.status == _SlaStatus.overdue
        ? AppColors.overdue
        : AppColors.atRisk;
    final status = task.status == _SlaStatus.overdue ? 'Overdue' : 'At Risk';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 58,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${task.assignee}  ·  Due ${task.deadline}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusBadge(label: status, color: color),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NoAttentionCard extends StatelessWidget {
  const _NoAttentionCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.celebration_outlined, color: AppColors.onTrack),
            SizedBox(width: 12),
            Expanded(
              child: Text('All clear — no tasks need attention right now.'),
            ),
          ],
        ),
      ),
    );
  }
}
