import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/text_to_speech_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextToSpeechService _ttsService = TextToSpeechService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme'),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) => themeProvider.toggleDarkMode(),
                  ),
                  SwitchListTile(
                    title: const Text('High Contrast'),
                    subtitle: const Text('Increase contrast for better visibility'),
                    value: themeProvider.highContrast,
                    onChanged: (value) => themeProvider.toggleHighContrast(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Font Size: ${themeProvider.fontSize.round()}',
                    style: theme.textTheme.titleMedium,
                  ),
                  Slider(
                    value: themeProvider.fontSize,
                    min: 14,
                    max: 28,
                    divisions: 7,
                    onChanged: (value) => themeProvider.setFontSize(value),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Voice Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice Settings',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<bool>(
                    future: _ttsService.isEnabled(),
                    builder: (context, snapshot) {
                      final isEnabled = snapshot.data ?? true;
                      return SwitchListTile(
                        title: const Text('Text-to-Speech'),
                        subtitle: const Text('Enable voice feedback'),
                        value: isEnabled,
                        onChanged: (value) {
                          _ttsService.setEnabled(value);
                          setState(() {});
                        },
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Test Voice'),
                    subtitle: const Text('Hear a sample of text-to-speech'),
                    trailing: ElevatedButton(
                      onPressed: () => _ttsService.speak('This is a test of the text to speech feature.'),
                      child: const Text('Test'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // About
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const ListTile(
                    title: Text('Voice-Controlled To-Do List'),
                    subtitle: Text('An accessible task management app with voice input and text-to-speech features.'),
                  ),
                  const ListTile(
                    title: Text('Version'),
                    subtitle: Text('1.0.0'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
