import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'task_list_screen.dart';
import 'calendar_screen.dart';
import 'notepad_screen.dart';
import 'statistics_screen.dart';
import 'theme_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _userId = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    debugPrint('HomeScreen: Loading user data...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('user_id');
      debugPrint('HomeScreen: userId from prefs = $userIdStr');

      setState(() {
        _userId = int.parse(userIdStr ?? '0');
        _userName = prefs.getString('user_name') ?? 'User';
      });
      debugPrint('HomeScreen: User data loaded - userId: $_userId, userName: $_userName');
    } catch (e) {
      debugPrint('HomeScreen: Error loading user data - $e');
    }
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(_userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Member since 2024', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskEase'),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Container(
          color: Theme.of(context).cardColor,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 45, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _userName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.person, color: Theme.of(context).primaryColor),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  _showProfileDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.color_lens, color: Theme.of(context).primaryColor),
                title: const Text('Theme Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final icons = [Icons.task_alt, Icons.calendar_month, Icons.edit_note, Icons.bar_chart];
            final titles = ['Tasks', 'Calendar', 'Notepad', 'Statistics'];
            final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];

            return GestureDetector(
              onTap: () {
                Widget screen;
                switch (index) {
                  case 0:
                    screen = const TaskListScreen();
                    break;
                  case 1:
                    screen = const CalendarScreen();
                    break;
                  case 2:
                    screen = const NotepadScreen();
                    break;
                  default:
                    screen = const StatisticsScreen();
                }
                Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors[index].withOpacity( isDark ? 0.3 : 0.15),
                      colors[index].withOpacity( isDark ? 0.1 : 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors[index].withOpacity( isDark ? 0.5 : 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors[index].withOpacity( 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icons[index], size: 40, color: colors[index]),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      titles[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
