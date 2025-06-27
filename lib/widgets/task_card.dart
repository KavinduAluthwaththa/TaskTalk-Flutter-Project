import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Slidable(
        key: ValueKey(task.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => _speakTask(context, taskProvider),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.volume_up,
              label: 'Speak',
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            SlidableAction(
              onPressed: (context) => _toggleCompletion(context, taskProvider),
              backgroundColor: task.isCompleted ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
              icon: task.isCompleted ? Icons.refresh : Icons.check,
              label: task.isCompleted ? 'Undo' : 'Done',
            ),
            SlidableAction(
              onPressed: (context) => _deleteTask(context, taskProvider),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ],
        ),
        child: Card(
          elevation: themeProvider.highContrast ? 8 : 4,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Completion checkbox
                      GestureDetector(
                        onTap: () => _toggleCompletion(context, taskProvider),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: task.isCompleted 
                                ? Colors.green 
                                : theme.colorScheme.outline,
                              width: 2,
                            ),
                            color: task.isCompleted 
                              ? Colors.green 
                              : Colors.transparent,
                          ),
                          child: task.isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Task content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                                color: task.isCompleted
                                  ? theme.colorScheme.onSurface.withOpacity(0.6)
                                  : null,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (task.description != null && task.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                task.description!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                ),
                              ),
                            ],
                            if (task.dueTime != null) ...[
                              const SizedBox(height: 8),
                              _buildDueTimeChip(context, task.dueTime!),
                            ],
                          ],
                        ),
                      ),
                      
                      // Action buttons
                      Column(
                        children: [
                          IconButton(
                            onPressed: () => _speakTask(context, taskProvider),
                            icon: const Icon(Icons.volume_up),
                            iconSize: 28,
                            tooltip: 'Read aloud',
                          ),
                          const SizedBox(height: 4),
                          if (task.hasReminder)
                            Icon(
                              Icons.notifications_active,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDueTimeChip(BuildContext context, DateTime dueTime) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isOverdue = dueTime.isBefore(now) && !task.isCompleted;
    final isToday = _isSameDay(dueTime, now);
    final isTomorrow = _isSameDay(dueTime, now.add(const Duration(days: 1)));

    String timeText;
    Color chipColor;
    Color textColor;

    if (isOverdue) {
      timeText = 'Overdue - ${DateFormat('MMM d, h:mm a').format(dueTime)}';
      chipColor = Colors.red.shade100;
      textColor = Colors.red.shade800;
    } else if (isToday) {
      timeText = 'Today - ${DateFormat('h:mm a').format(dueTime)}';
      chipColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
    } else if (isTomorrow) {
      timeText = 'Tomorrow - ${DateFormat('h:mm a').format(dueTime)}';
      chipColor = Colors.blue.shade100;
      textColor = Colors.blue.shade800;
    } else {
      timeText = DateFormat('MMM d, h:mm a').format(dueTime);
      chipColor = theme.colorScheme.surfaceContainerHighest;
      textColor = theme.colorScheme.onSurface;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning : Icons.schedule,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            timeText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _toggleCompletion(BuildContext context, TaskProvider taskProvider) {
    HapticFeedback.lightImpact();
    taskProvider.toggleTaskCompletion(task.id!);
  }

  void _deleteTask(BuildContext context, TaskProvider taskProvider) {
    HapticFeedback.mediumImpact();
    
    // Show confirmation dialog for accessibility
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text('Are you sure you want to delete "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                taskProvider.deleteTask(task.id!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _speakTask(BuildContext context, TaskProvider taskProvider) {
    HapticFeedback.lightImpact();
    taskProvider.speakTask(task);
  }
}
