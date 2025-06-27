import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/speech_to_text_service.dart';
import '../services/text_to_speech_service.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class VoiceInputButton extends StatefulWidget {
  final VoidCallback? onTaskAdded;

  const VoiceInputButton({
    super.key,
    this.onTaskAdded,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with TickerProviderStateMixin {
  final SpeechToTextService _speechService = SpeechToTextService();
  final TextToSpeechService _ttsService = TextToSpeechService();
  
  bool _isListening = false;
  String _recognizedText = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeServices();
  }

  void _initializeAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeServices() async {
    await _ttsService.initialize();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice input button
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? _pulseAnimation.value : 1.0,
                child: FloatingActionButton.large(
                  onPressed: _toggleListening,
                  backgroundColor: _isListening 
                    ? Colors.red 
                    : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  heroTag: "voice_input",
                  tooltip: _isListening ? 'Stop listening' : 'Start voice input',
                  child: Icon(
                    _isListening ? Icons.mic_off : Icons.mic,
                    size: 36,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Status text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusText(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Recognized text
          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recognized:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _recognizedText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _createTaskFromSpeech,
                        icon: const Icon(Icons.add_task),
                        label: const Text('Create Task'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _clearRecognizedText,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusText() {
    if (_isListening) {
      return 'Listening... Speak your task';
    } else if (_recognizedText.isNotEmpty) {
      return 'Tap "Create Task" to add it';
    } else {
      return 'Tap the microphone to add a task with your voice';
    }
  }

  Future<void> _toggleListening() async {
    HapticFeedback.mediumImpact();

    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    try {
      // Clear previous text
      _clearRecognizedText();
      
      // Provide voice feedback
      await _ttsService.speak("I'm listening. Please speak your task.");
      
      // Wait a moment for TTS to finish
      await Future.delayed(const Duration(milliseconds: 1500));
      
      bool initialized = await _speechService.initialize();
      if (!initialized) {
        await _ttsService.speak("Sorry, I couldn't access the microphone. Please check permissions.");
        return;
      }

      await _speechService.startListening(
        onResult: (text) {
          setState(() {
            _recognizedText = text;
          });
        },
      );

      setState(() {
        _isListening = true;
      });

      // Start pulsing animation
      _pulseController.repeat(reverse: true);

    } catch (e) {
      print('Error starting speech recognition: $e');
      await _ttsService.speak("Sorry, there was an error with voice recognition.");
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speechService.stopListening();
      
      setState(() {
        _isListening = false;
      });

      // Stop pulsing animation
      _pulseController.stop();
      _pulseController.reset();

      if (_recognizedText.isNotEmpty) {
        await _ttsService.speak("I heard: $_recognizedText");
      } else {
        await _ttsService.speak("I didn't hear anything. Please try again.");
      }

    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
  }

  Future<void> _createTaskFromSpeech() async {
    if (_recognizedText.isEmpty) return;

    HapticFeedback.lightImpact();

    try {
      // Parse the recognized text
      final parseResult = _speechService.parseTaskFromSpeech(_recognizedText);
      
      // Create the task
      final task = Task(
        title: parseResult.title,
        description: parseResult.description,
        dueTime: parseResult.dueTime,
        hasReminder: parseResult.hasReminder,
      );

      // Add to database
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.addTask(task);

      // Clear the recognized text
      _clearRecognizedText();

      // Notify parent
      if (widget.onTaskAdded != null) {
        widget.onTaskAdded!();
      }

      // Provide confirmation
      String confirmationText = "Task created: ${task.title}";
      if (task.dueTime != null) {
        confirmationText += " scheduled for ${_formatTimeForConfirmation(task.dueTime!)}";
      }
      await _ttsService.speak(confirmationText);

    } catch (e) {
      print('Error creating task from speech: $e');
      await _ttsService.speak("Sorry, there was an error creating the task. Please try again.");
    }
  }

  String _formatTimeForConfirmation(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (taskDate == today) {
      return "today at ${_formatTime(dateTime)}";
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return "tomorrow at ${_formatTime(dateTime)}";
    } else {
      return "${dateTime.month}/${dateTime.day} at ${_formatTime(dateTime)}";
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour == 0 ? 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $amPm";
  }

  void _clearRecognizedText() {
    setState(() {
      _recognizedText = '';
    });
  }
}
