import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  late FlutterTts _flutterTts;
  bool _isInitialized = false;

  TextToSpeechService._internal();

  factory TextToSpeechService() => _instance;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _flutterTts = FlutterTts();
    
    // Set default settings
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Slower for elderly users
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);

    // Load user preferences
    await _loadUserPreferences();

    _isInitialized = true;
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    final speechRate = prefs.getDouble('tts_speech_rate') ?? 0.5;
    final volume = prefs.getDouble('tts_volume') ?? 0.8;
    final pitch = prefs.getDouble('tts_pitch') ?? 1.0;
    final language = prefs.getString('tts_language') ?? 'en-US';

    await _flutterTts.setSpeechRate(speechRate);
    await _flutterTts.setVolume(volume);
    await _flutterTts.setPitch(pitch);
    await _flutterTts.setLanguage(language);
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    
    // Check if TTS is enabled
    final prefs = await SharedPreferences.getInstance();
    final isTtsEnabled = prefs.getBool('tts_enabled') ?? true;
    
    if (!isTtsEnabled) return;

    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    if (!_isInitialized) return;
    await _flutterTts.stop();
  }

  Future<void> pause() async {
    if (!_isInitialized) return;
    await _flutterTts.pause();
  }

  // Speak task with proper formatting
  Future<void> speakTask(String title, {String? description, DateTime? dueTime}) async {
    String textToSpeak = "Task: $title";
    
    if (description != null && description.isNotEmpty) {
      textToSpeak += ". Description: $description";
    }
    
    if (dueTime != null) {
      final timeString = _formatTimeForSpeech(dueTime);
      textToSpeak += ". Due: $timeString";
    }
    
    await speak(textToSpeak);
  }

  // Speak multiple tasks
  Future<void> speakTaskList(List<String> taskTitles) async {
    if (taskTitles.isEmpty) {
      await speak("You have no tasks.");
      return;
    }

    String textToSpeak = "You have ${taskTitles.length} task${taskTitles.length == 1 ? '' : 's'}. ";
    
    for (int i = 0; i < taskTitles.length; i++) {
      textToSpeak += "${i + 1}. ${taskTitles[i]}. ";
    }
    
    await speak(textToSpeak);
  }

  String _formatTimeForSpeech(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String timeString = "";
    
    if (taskDate == today) {
      timeString = "today at ";
    } else if (taskDate == today.add(const Duration(days: 1))) {
      timeString = "tomorrow at ";
    } else {
      timeString = "on ${dateTime.month}/${dateTime.day} at ";
    }
    
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final amPm = dateTime.hour >= 12 ? "PM" : "AM";
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    timeString += "$hour:$minute $amPm";
    
    return timeString;
  }

  // Settings methods
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) await initialize();
    await _flutterTts.setSpeechRate(rate);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_speech_rate', rate);
  }

  Future<void> setVolume(double volume) async {
    if (!_isInitialized) await initialize();
    await _flutterTts.setVolume(volume);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_volume', volume);
  }

  Future<void> setLanguage(String language) async {
    if (!_isInitialized) await initialize();
    await _flutterTts.setLanguage(language);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_language', language);
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_enabled', enabled);
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tts_enabled') ?? true;
  }
}
