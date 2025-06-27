import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/voice_input_button.dart';
import '../services/text_to_speech_service.dart';
import 'add_task_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextToSpeechService _ttsService = TextToSpeechService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
  }

  void _initializeServices() async {
    await _ttsService.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        elevation: 2,
        actions: [
          // Speak all tasks button
          IconButton(
            onPressed: _speakAllTasks,
            icon: const Icon(Icons.record_voice_over),
            iconSize: 28,
            tooltip: 'Read all tasks aloud',
          ),
          // Settings button
          IconButton(
            onPressed: () => _navigateToSettings(context),
            icon: const Icon(Icons.settings),
            iconSize: 28,
            tooltip: 'Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: TextStyle(
            fontSize: themeProvider.fontSize,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: themeProvider.fontSize - 2,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.list),
              text: 'All Tasks',
            ),
            Tab(
              icon: Icon(Icons.today),
              text: 'Today',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Completed',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllTasksTab(),
          _buildTodayTasksTab(),
          _buildCompletedTasksTab(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice Input Button (Primary)
          const VoiceInputButton(),
          
          const SizedBox(height: 16),
          
          // Manual Add Task Button (Accessibility fallback)
          FloatingActionButton(
            onPressed: () => _navigateToAddTask(context),
            heroTag: "manual_add",
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            tooltip: 'Add task manually',
            child: const Icon(Icons.add, size: 28),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAllTasksTab() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        if (taskProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 3),
          );
        }

        final incompleteTasks = taskProvider.incompleteTasks;
        
        if (incompleteTasks.isEmpty) {
          return _buildEmptyState(
            icon: Icons.task_alt,
            title: 'No tasks yet!',
            subtitle: 'Tap the microphone below to add your first task using voice input, or use the + button for manual entry.',
          );
        }

        return RefreshIndicator(
          onRefresh: taskProvider.loadTasks,
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 200, // Space for floating action buttons
            ),
            itemCount: incompleteTasks.length,
            itemBuilder: (context, index) {
              final task = incompleteTasks[index];
              return TaskCard(
                key: ValueKey(task.id),
                task: task,
                onTap: () => _showTaskDetails(context, task),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTodayTasksTab() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        if (taskProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 3),
          );
        }

        final todayTasks = taskProvider.tasksToday;
        final overdueTasks = taskProvider.overdueTasks;
        final allTodayTasks = [...overdueTasks, ...todayTasks];
        
        if (allTodayTasks.isEmpty) {
          return _buildEmptyState(
            icon: Icons.today,
            title: 'No tasks for today!',
            subtitle: 'You\'re all caught up for today. Great job!',
          );
        }

        return RefreshIndicator(
          onRefresh: taskProvider.loadTasks,
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 200,
            ),
            itemCount: allTodayTasks.length + (overdueTasks.isNotEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              // Show overdue header if there are overdue tasks
              if (overdueTasks.isNotEmpty && index == 0) {
                return _buildSectionHeader('Overdue Tasks', Colors.red);
              }

              // Adjust index for overdue header
              final taskIndex = overdueTasks.isNotEmpty ? index - 1 : index;
              
              // Show today header when switching from overdue to today tasks
              if (overdueTasks.isNotEmpty && taskIndex == overdueTasks.length) {
                return _buildSectionHeader('Today\'s Tasks', Colors.blue);
              }

              // Calculate actual task index
              final actualTaskIndex = overdueTasks.isNotEmpty && taskIndex >= overdueTasks.length
                  ? taskIndex - 1  // Account for today header
                  : taskIndex;

              if (actualTaskIndex >= allTodayTasks.length) return const SizedBox();

              final task = allTodayTasks[actualTaskIndex];
              return TaskCard(
                key: ValueKey(task.id),
                task: task,
                onTap: () => _showTaskDetails(context, task),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCompletedTasksTab() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        if (taskProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 3),
          );
        }

        final completedTasks = taskProvider.completedTasks;
        
        if (completedTasks.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'No completed tasks',
            subtitle: 'Completed tasks will appear here.',
          );
        }

        return RefreshIndicator(
          onRefresh: taskProvider.loadTasks,
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 200,
            ),
            itemCount: completedTasks.length,
            itemBuilder: (context, index) {
              final task = completedTasks[index];
              return TaskCard(
                key: ValueKey(task.id),
                task: task,
                onTap: () => _showTaskDetails(context, task),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TaskDetailsBottomSheet(task: task),
    );
  }

  Future<void> _speakAllTasks() async {
    HapticFeedback.mediumImpact();
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    await taskProvider.speakAllTasks();
  }

  void _navigateToAddTask(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddTaskPage(),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }
}

class TaskDetailsBottomSheet extends StatelessWidget {
  final Task task;

  const TaskDetailsBottomSheet({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.title,
                        style: theme.textTheme.headlineSmall,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      if (task.description != null && task.description!.isNotEmpty) ...[
                        Text(
                          'Description',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.description!,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Due time
                      if (task.dueTime != null) ...[
                        Text(
                          'Due Time',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${task.dueTime!.day}/${task.dueTime!.month}/${task.dueTime!.year} at ${task.dueTime!.hour}:${task.dueTime!.minute.toString().padLeft(2, '0')}',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Status
                      Text(
                        'Status',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(task.isCompleted ? 'Completed' : 'Pending'),
                        backgroundColor: task.isCompleted 
                          ? Colors.green.shade100 
                          : Colors.orange.shade100,
                        side: BorderSide(
                          color: task.isCompleted 
                            ? Colors.green 
                            : Colors.orange,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                taskProvider.speakTask(task);
                              },
                              icon: const Icon(Icons.volume_up),
                              label: const Text('Read Aloud'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                taskProvider.toggleTaskCompletion(task.id!);
                              },
                              icon: Icon(task.isCompleted ? Icons.refresh : Icons.check),
                              label: Text(task.isCompleted ? 'Mark Pending' : 'Mark Done'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: task.isCompleted ? Colors.orange : Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
