import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'register.dart';
import 'profil.dart';

class StudentLoginPage extends StatefulWidget {
  const StudentLoginPage({Key? key}) : super(key: key);

  @override
  State<StudentLoginPage> createState() => _StudentLoginPageState();
}

class _StudentLoginPageState extends State<StudentLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  // Theme colors
  final Color _primaryColor = const Color(0xFF3498DB);
  final Color _accentColor = const Color(0xFF2ECC71);
  final Color _warningColor = const Color(0xFFF39C12);
  final Color _darkColor = const Color(0xFF2C3E50);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> _checkNetworkConnection() async {
    try {
      final response = await http.get(Uri.parse('http://google.com')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Check internet connection
      if (!await _checkNetworkConnection()) {
        _showErrorDialog('No internet connection. Please check your network.');
        setState(() => _isLoading = false);
        return;
      }

      try {
        // Use 10.0.2.2 for Android emulators, localhost for iOS
        final uri = Uri.parse('http://10.0.2.2:5002/api/auth/login');

        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          // Access token
          final userData = responseData['user'];
          final token = userData['token'];

          if (token == null) {
            throw Exception('Token not found in response');
          }

          // Save user data
          await _authService.saveUserData({
            'token': token,
            'id': userData['id'],
            'name': userData['name'],
            'email': userData['email'],
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
          );
        } else {
          final errorData = json.decode(response.body);
          _showErrorDialog(errorData['message'] ?? 'Login failed: ${response.statusCode}');
        }
      } on SocketException {
        _showErrorDialog('Connection error. Check your network.');
      } on TimeoutException {
        _showErrorDialog('Server took too long to respond.');
      } on http.ClientException catch (e) {
        _showErrorDialog('Client error: ${e.message}');
      } catch (e) {
        _showErrorDialog('Unexpected error: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Graduation icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Graduation cap
                          Container(
                            width: 80,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _darkColor,
                            ),
                            child: Stack(
                              children: [
                                // Main cap part
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  right: 10,
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _darkColor,
                                    ),
                                  ),
                                ),
                                // Cap tassel
                                Positioned(
                                  top: 0,
                                  right: 15,
                                  child: Container(
                                    width: 3,
                                    height: 25,
                                    color: _warningColor,
                                  ),
                                ),
                                Positioned(
                                  top: 20,
                                  right: 10,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _warningColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Diploma
                          Positioned(
                            bottom: 10,
                            left: 20,
                            child: Transform.rotate(
                              angle: -0.3,
                              child: Container(
                                width: 40,
                                height: 25,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5E6B3),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: _warningColor,
                                    width: 2,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: 2,
                                      top: 2,
                                      child: Container(
                                        width: 15,
                                        height: 15,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE74C3C),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Title
                    Text(
                      'Student Login',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _darkColor,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@(etu\.[\w-]+\.\w+|[\w-]+\.\w+)$').hasMatch(value)) {
                          return 'Please enter a valid student email';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Student email',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: _primaryColor,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: _primaryColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                            : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Register button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Register()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _primaryColor,
                          elevation: 2,
                          side: BorderSide(color: _primaryColor, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Forgot password link
                    TextButton(
                      onPressed: _isLoading ? null : () => _showPasswordResetDialog(),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: _warningColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPasswordResetDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Password Reset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email to receive a reset link',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Student email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final uri = Uri.parse('http://10.0.2.2:5002/api/auth/forgot-password');
                final response = await http.post(
                  uri,
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({'email': emailController.text.trim()}),
                ).timeout(const Duration(seconds: 10));

                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reset email sent!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(ctx).pop();
                } else {
                  final errorData = json.decode(response.body);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorData['message'] ?? 'Unknown error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } on TimeoutException {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Server took too long to respond'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}