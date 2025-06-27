import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpeechToTextService {
  static final SpeechToTextService _instance = SpeechToTextService._internal();
  late SpeechToText _speechToText;
  bool _isInitialized = false;
  bool _isListening = false;
  String _recognizedText = '';

  SpeechToTextService._internal();

  factory SpeechToTextService() => _instance;

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _speechToText = SpeechToText();
    
    // Request microphone permission
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      return false;
    }

    // Initialize speech to text
    bool available = await _speechToText.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );

    _isInitialized = available;
    return available;
  }

  Future<void> startListening({
    required Function(String) onResult,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      bool initialized = await initialize();
      if (!initialized) return;
    }

    if (_isListening) return;

    // Get user preferred language
    final prefs = await SharedPreferences.getInstance();
    final language = localeId ?? prefs.getString('speech_language') ?? 'en_US';

    await _speechToText.listen(
      onResult: (result) {
        _recognizedText = result.recognizedWords;
        onResult(_recognizedText);
      },
      localeId: language,
      listenFor: const Duration(seconds: 30), // Extended for elderly users
      pauseFor: const Duration(seconds: 3),   // Longer pause detection
      partialResults: true,
      cancelOnError: true,
    );

    _isListening = true;
  }

  Future<void> stopListening() async {
    if (!_isInitialized || !_isListening) return;

    await _speechToText.stop();
    _isListening = false;
  }

  Future<void> cancelListening() async {
    if (!_isInitialized || !_isListening) return;

    await _speechToText.cancel();
    _isListening = false;
    _recognizedText = '';
  }

  void _onSpeechStatus(String status) {
    switch (status) {
      case 'listening':
        _isListening = true;
        break;
      case 'notListening':
      case 'done':
        _isListening = false;
        break;
    }
  }

  void _onSpeechError(dynamic error) {
    print('Speech recognition error: $error');
    _isListening = false;
  }

  // Parse spoken text to extract task components
  TaskParseResult parseTaskFromSpeech(String spokenText) {
    String text = spokenText.toLowerCase().trim();
    
    // Clean up common speech-to-text issues
    text = _cleanupSpeechText(text);
    
    // Extract task title
    String title = _extractTaskTitle(text);
    
    // Extract time information
    DateTime? dueTime = _extractTimeFromText(text);
    
    // Extract description (everything after "to" or task action words)
    String? description = _extractDescription(text, title);
    
    return TaskParseResult(
      title: title,
      description: description,
      dueTime: dueTime,
      hasReminder: dueTime != null,
    );
  }

  String _cleanupSpeechText(String text) {
    // Replace common speech-to-text mistakes
    text = text.replaceAll(RegExp(r'\bremind me to\b'), 'remind me to');
    text = text.replaceAll(RegExp(r'\btake medicine\b'), 'take medicine');
    text = text.replaceAll(RegExp(r'\bcall doctor\b'), 'call doctor');
    text = text.replaceAll(RegExp(r'\bbuy groceries\b'), 'buy groceries');
    
    return text;
  }

  String _extractTaskTitle(String text) {
    // Remove common prefixes
    List<String> prefixes = [
      'remind me to ',
      'i need to ',
      'add task to ',
      'add a task to ',
      'create task to ',
      'new task to ',
      'task to ',
      'to ',
    ];
    
    String cleanText = text;
    for (String prefix in prefixes) {
      if (cleanText.startsWith(prefix)) {
        cleanText = cleanText.substring(prefix.length);
        break;
      }
    }
    
    // Extract the main action (everything before time indicators)
    List<String> timeIndicators = [' at ', ' on ', ' by ', ' in ', ' tomorrow', ' today'];
    
    for (String indicator in timeIndicators) {
      int index = cleanText.indexOf(indicator);
      if (index != -1) {
        cleanText = cleanText.substring(0, index);
        break;
      }
    }
    
    return cleanText.trim().isEmpty ? text : cleanText.trim();
  }

  DateTime? _extractTimeFromText(String text) {
    final now = DateTime.now();
    
    // Look for time patterns
    RegExp timePattern = RegExp(r'(\d{1,2}):?(\d{2})?\s*(am|pm|a\.m\.|p\.m\.)?', caseSensitive: false);
    Match? timeMatch = timePattern.firstMatch(text);
    
    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      int minute = timeMatch.group(2) != null ? int.parse(timeMatch.group(2)!) : 0;
      String? ampm = timeMatch.group(3)?.toLowerCase();
      
      // Convert to 24-hour format
      if (ampm != null && ampm.contains('p') && hour != 12) {
        hour += 12;
      } else if (ampm != null && ampm.contains('a') && hour == 12) {
        hour = 0;
      }
      
      // Determine the date
      DateTime targetDate = now;
      
      if (text.contains('tomorrow')) {
        targetDate = now.add(const Duration(days: 1));
      } else if (text.contains('today')) {
        targetDate = now;
      } else {
        // If no date specified and time is in the past, assume tomorrow
        final timeToday = DateTime(now.year, now.month, now.day, hour, minute);
        if (timeToday.isBefore(now)) {
          targetDate = now.add(const Duration(days: 1));
        }
      }
      
      return DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
    }
    
    // Look for relative time expressions
    if (text.contains('in an hour') || text.contains('in 1 hour')) {
      return now.add(const Duration(hours: 1));
    } else if (text.contains('in 30 minutes') || text.contains('in thirty minutes')) {
      return now.add(const Duration(minutes: 30));
    } else if (text.contains('tomorrow')) {
      return DateTime(now.year, now.month, now.day + 1, 9, 0); // Default to 9 AM
    }
    
    return null;
  }

  String? _extractDescription(String text, String title) {
    // For now, return null as description will be handled separately
    // This can be enhanced to extract additional context
    return null;
  }

  // Get available locales
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) await initialize();
    return await _speechToText.locales();
  }
}

class TaskParseResult {
  final String title;
  final String? description;
  final DateTime? dueTime;
  final bool hasReminder;

  TaskParseResult({
    required this.title,
    this.description,
    this.dueTime,
    this.hasReminder = false,
  });
}
