import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  ThemeMode _currentThemeMode = ThemeMode.system;
  Color _currentColor = const Color(0xFF6200EE);

  @override
  void initState() {
    super.initState();
    _currentThemeMode = ThemeService.themeMode;
    _currentColor = ThemeService.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance Section
            Card(
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Appearance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.light_mode),
                      title: const Text('Light Mode'),
                      trailing: Radio<ThemeMode>(
                        value: ThemeMode.light,
                        groupValue: _currentThemeMode,
                        onChanged: (value) {
                          setState(() {
                            _currentThemeMode = value!;
                            ThemeService.setThemeMode(value);
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _currentThemeMode = ThemeMode.light;
                          ThemeService.setThemeMode(ThemeMode.light);
                        });
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.dark_mode),
                      title: const Text('Dark Mode'),
                      trailing: Radio<ThemeMode>(
                        value: ThemeMode.dark,
                        groupValue: _currentThemeMode,
                        onChanged: (value) {
                          setState(() {
                            _currentThemeMode = value!;
                            ThemeService.setThemeMode(value);
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _currentThemeMode = ThemeMode.dark;
                          ThemeService.setThemeMode(ThemeMode.dark);
                        });
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings_system_daydream),
                      title: const Text('System Default'),
                      trailing: Radio<ThemeMode>(
                        value: ThemeMode.system,
                        groupValue: _currentThemeMode,
                        onChanged: (value) {
                          setState(() {
                            _currentThemeMode = value!;
                            ThemeService.setThemeMode(value);
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _currentThemeMode = ThemeMode.system;
                          ThemeService.setThemeMode(ThemeMode.system);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Theme Colors Section
            Card(
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Theme Color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: ThemeService.rainbowColors.map((color) {
                        final isSelected = _currentColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentColor = color;
                              ThemeService.setPrimaryColor(color);
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity( 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Preview Card
            Card(
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).primaryColor.withOpacity( 0.3)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Sample Button',
                                style: TextStyle(color: _currentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).primaryColor.withOpacity( 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.task_alt, color: Theme.of(context).primaryColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Sample Task Card',
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                                Icon(Icons.check_circle, color: Colors.green),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
