import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _userEmail = '';
  String _memberSince = '2024';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id') ?? '1';
      _userName = prefs.getString('user_name') ?? 'TaskEase User';
      _userEmail = prefs.getString('user_email') ?? 'user@taskease.com';
      _memberSince = prefs.getString('member_since') ?? '2024';
    });
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (newPasswordController.text == confirmPasswordController.text) {
                // In a real app, you would verify current password and save new one
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password changed!'), backgroundColor: Colors.green),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity( 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Member since $_memberSince',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Card(
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.badge, color: Theme.of(context).primaryColor),
                          title: const Text('User ID'),
                          subtitle: Text(_userId),
                          trailing: Icon(Icons.copy, size: 18, color: Theme.of(context).primaryColor),
                          onTap: () {
                            // Copy user ID to clipboard
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User ID copied'), duration: Duration(seconds: 1)),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.email, color: Theme.of(context).primaryColor),
                          title: const Text('Email Address'),
                          subtitle: Text(_userEmail),
                          trailing: Icon(Icons.edit, size: 18, color: Theme.of(context).primaryColor),
                          onTap: () {
                            // Edit email
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.lock, color: Theme.of(context).primaryColor),
                          title: const Text('Change Password'),
                          subtitle: const Text('********'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: _changePassword,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                          title: const Text('Account Created'),
                          subtitle: Text('$_memberSince'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.task_alt, color: Theme.of(context).primaryColor),
                          title: const Text('Total Tasks Created'),
                          subtitle: const Text('Loading...'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.check_circle, color: Colors.green),
                          title: const Text('Completion Rate'),
                          subtitle: const Text('Loading...'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
