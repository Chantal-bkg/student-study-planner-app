import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'login.dart';

class ProfileSettingsPage extends StatefulWidget {
  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  // User data
  String _userName = "";
  String _userEmail = "";
  String _userAvatar = "";
  String _authToken = "";
  String _accountType = "Student Account";
  bool _isLoading = true;
  String? _errorMessage;

  // Pomodoro settings
  int _workDuration = 25;
  int _shortBreakDuration = 5;
  int _longBreakDuration = 15;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Form states
  bool _isEditingProfile = false;
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      if (token.isEmpty) {
        _redirectToLogin();
        return;
      }

      setState(() {
        _authToken = token;
      });

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5002/api/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('API Response: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = json.decode(response.body);
        setState(() {
          _userName = userData['name']?.toString() ?? 'Not defined';
          _userEmail = userData['email']?.toString() ?? 'Not defined';
          _userAvatar = _getInitials(_userName);
          _nameController.text = _userName;
          _emailController.text = _userEmail;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _showSnackBar('Session expired. Please log in again.');
        _redirectToLogin();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Loading error: ${response.statusCode}';
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error: $e';
      });
    }
  }

  void _redirectToLogin() {
    Future.delayed(Duration.zero, () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "";
    final parts = name.split(' ');
    if (parts.length > 1) {
      return parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
    } else if (parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return "?";
  }

  Future<void> _updateUserProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.put(
        Uri.parse('http://10.0.2.2:5002/api/users/me'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'name': _nameController.text,
          'email': _emailController.text,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final updatedUser = json.decode(response.body);
        setState(() {
          _userName = updatedUser['name']?.toString() ?? _userName;
          _userEmail = updatedUser['email']?.toString() ?? _userEmail;
          _userAvatar = _getInitials(_userName);
          _isEditingProfile = false;
        });
        _showSnackBar('Profile updated successfully');
      } else {
        final errorBody = json.decode(response.body);
        _showSnackBar('Update failed: ${errorBody['message']}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Connection error: $e');
    }
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      _showSnackBar('Passwords do not match');
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5002/api/users/change-password'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'currentPassword': _currentPasswordController.text,
          'newPassword': newPassword,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        _showSnackBar('Password changed successfully');
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          _isChangingPassword = false;
          _obscureCurrentPassword = true;
          _obscureNewPassword = true;
          _obscureConfirmPassword = true;
        });
      } else {
        final errorBody = json.decode(response.body);
        _showSnackBar('Change failed: ${errorBody['message']}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Connection error: $e');
    }
  }

  Future<void> _deleteUserAccount() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.delete(
        Uri.parse('http://10.0.2.2:5002/api/users/me'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('authToken');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final errorBody = json.decode(response.body);
        _showSnackBar('Deletion failed: ${errorBody['message']}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Connection error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading your profile...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error', style: TextStyle(fontSize: 24, color: Colors.red)),
              SizedBox(height: 20),
              Text(_errorMessage!),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadUserData,
                child: Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Settings & Profile'),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          if (_isEditingProfile || _isChangingPassword)
            TextButton(
              onPressed: _cancelEditing,
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            SizedBox(height: 24),
            _buildProfileSection(),
            SizedBox(height: 24),
            _buildPasswordSection(),
            SizedBox(height: 24),
            _buildPomodoroSettings(),
            SizedBox(height: 24),
            _buildAppSettings(),
            SizedBox(height: 24),
            _buildLogoutSection(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          )],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue,
            radius: 35,
            child: Text(
              _userAvatar,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _accountType,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _isEditingProfile = true),
            icon: Icon(Icons.edit, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              if (_isEditingProfile)
                ElevatedButton(
                  onPressed: _updateUserProfile,
                  child: Text('Save'),
                ),
            ],
          ),
          SizedBox(height: 20),
          TextField(
            controller: _nameController,
            enabled: _isEditingProfile,
            decoration: InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _emailController,
            enabled: _isEditingProfile,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Security',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              if (_isChangingPassword)
                ElevatedButton(
                  onPressed: _changePassword,
                  child: Text('Confirm'),
                ),
            ],
          ),
          SizedBox(height: 16),
          if (!_isChangingPassword) ...[
            ListTile(
              leading: Icon(Icons.lock, color: Colors.orange),
              title: Text('Change password'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => setState(() => _isChangingPassword = true),
            ),
          ] else ...[
            TextField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              decoration: InputDecoration(
                labelText: 'Current password',
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrentPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: 'New password',
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNewPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: Icon(Icons.lock_reset),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPomodoroSettings() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Pomodoro Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildDurationSetting(
            'Work duration',
            _workDuration,
            'minutes',
            Colors.red,
                (value) => setState(() => _workDuration = value),
          ),
          SizedBox(height: 16),
          _buildDurationSetting(
            'Short break',
            _shortBreakDuration,
            'minutes',
            Colors.green,
                (value) => setState(() => _shortBreakDuration = value),
          ),
          SizedBox(height: 16),
          _buildDurationSetting(
            'Long break',
            _longBreakDuration,
            'minutes',
            Colors.blue,
                (value) => setState(() => _longBreakDuration = value),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettings() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.notifications, color: Colors.orange),
            title: Text('Notifications'),
            subtitle: Text('Manage push notifications'),
            trailing: Switch(
              value: true,
              onChanged: (value) => _showSnackBar('Notifications ${value ? 'enabled' : 'disabled'}'),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.vibration, color: Colors.purple),
            title: Text('Vibrations'),
            subtitle: Text('Vibrate at session end'),
            trailing: Switch(
              value: true,
              onChanged: (value) => _showSnackBar('Vibrations ${value ? 'enabled' : 'disabled'}'),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.dark_mode, color: Colors.grey.shade700),
            title: Text('Dark theme'),
            subtitle: Text('Switch to dark mode'),
            trailing: Switch(
              value: false,
              onChanged: (value) => _showSnackBar('Dark theme ${value ? 'enabled' : 'disabled'}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.help_outline, color: Colors.blue),
            title: Text('Help & Support'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showSnackBar('Redirecting to help...'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info_outline, color: Colors.grey),
            title: Text('About'),
            subtitle: Text('Version 1.0.0'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showAboutDialog,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Log out',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
            onTap: _showLogoutDialog,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text(
              'Delete my account',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSetting(
      String title,
      int value,
      String unit,
      Color color,
      Function(int) onChanged,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$value $unit',
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
              icon: Icon(Icons.remove_circle_outline),
              color: color,
            ),
            Container(
              width: 40,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: value < 60 ? () => onChanged(value + 1) : null,
              icon: Icon(Icons.add_circle_outline),
              color: color,
            ),
          ],
        ),
      ],
    );
  }

  void _cancelEditing() {
    setState(() {
      _isEditingProfile = false;
      _isChangingPassword = false;
      _nameController.text = _userName;
      _emailController.text = _userEmail;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete account'),
          ],
        ),
        content: Text('Are you sure you want to delete your account? This action is irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUserAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text('Log out'),
            ],
          ),
          content: Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Log out'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('About'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student Application'),
              Text('Version 1.0.0'),
              SizedBox(height: 16),
              Text('Developed to enhance student productivity with time management and organization tools.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }
}