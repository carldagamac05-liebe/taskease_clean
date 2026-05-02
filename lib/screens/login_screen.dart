import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final remember = prefs.getBool('remember_me') ?? false;

    if (remember && savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Save user session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', '1');
    await prefs.setString('user_name', _emailController.text.split('@')[0]);
    await prefs.setString('user_email', _emailController.text.trim());
    await prefs.setBool('is_logged_in', true);

    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text.trim());
      await prefs.setBool('remember_me', true);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),

                          // Logo
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.task_alt,
                              size: 50,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // App Name
                          const Text(
                            'TaskEase',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Tagline
                          Text(
                            'Smart Task Manager',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Login Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[900] : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Email Field
                                TextField(
                                  controller: _emailController,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                                    prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).primaryColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 12),

                                // Password Field
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                                    prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).primaryColor),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Remember Me & Forgot Password
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) => setState(() => _rememberMe = value ?? false),
                                            activeColor: Theme.of(context).primaryColor,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Remember me',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.white70 : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Forgot password logic
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Contact support to reset password')),
                                        );
                                      },
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : const Text(
                                      'Login',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Sign Up Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account?",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                        );
                                      },
                                      child: Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}