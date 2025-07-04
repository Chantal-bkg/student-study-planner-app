import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  String _accountType = "Compte Étudiant";
  bool _isLoading = true;
  String? _errorMessage;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Form states
  bool _isEditingProfile = false;
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

      debugPrint('Réponse API: ${response.statusCode}');
      debugPrint('Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = json.decode(response.body);

        // Vérification des clés
        debugPrint('Clés disponibles: ${userData.keys.join(', ')}');

        setState(() {
          _userName = userData['name']?.toString() ?? 'Non défini';
          _userEmail = userData['email']?.toString() ?? 'Non défini';
          _userAvatar = _getInitials(_userName);
          _nameController.text = _userName;
          _emailController.text = _userEmail;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _showSnackBar('Session expirée. Veuillez vous reconnecter.');
        _redirectToLogin();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur de chargement: ${response.statusCode}';
        });
      }
    } catch (e) {
      debugPrint('Erreur: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur de connexion: $e';
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
      _showSnackBar('Veuillez remplir tous les champs');
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
        _showSnackBar('Profil mis à jour avec succès');
      } else {
        _showSnackBar('Échec de la mise à jour: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Erreur de connexion: $e');
    }
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      _showSnackBar('Les mots de passe ne correspondent pas');
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('Le mot de passe doit contenir au moins 6 caractères');
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
        _showSnackBar('Mot de passe modifié avec succès');
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          _obscureCurrentPassword = true;
          _obscureNewPassword = true;
          _obscureConfirmPassword = true;
        });
      } else {
        final errorBody = json.decode(response.body);
        _showSnackBar('Échec de la modification: ${errorBody['message']}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Erreur de connexion: $e');
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
        _showSnackBar('Échec de la suppression: ${errorBody['message']}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Erreur de connexion: $e');
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
              Text('Chargement de votre profil...'),
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
              Text('Erreur', style: TextStyle(fontSize: 24, color: Colors.red)),
              SizedBox(height: 20),
              Text(_errorMessage!),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadUserData,
                child: Text('Réessayer'),
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
        title: Text('Paramètres & Profil'),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          if (_isEditingProfile)
            TextButton(
              onPressed: () {
                setState(() => _isEditingProfile = false);
                _nameController.text = _userName;
                _emailController.text = _userEmail;
              },
              child: Text('Annuler', style: TextStyle(color: Colors.white)),
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
          ),
        ],
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
                'Informations personnelles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              if (_isEditingProfile)
                ElevatedButton(
                  onPressed: _updateUserProfile,
                  child: Text('Sauvegarder'),
                ),
            ],
          ),
          SizedBox(height: 20),
          TextField(
            controller: _nameController,
            enabled: _isEditingProfile,
            decoration: InputDecoration(
              labelText: 'Nom complet',
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
              labelText: 'Adresse email',
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
          Text(
            'Sécurité',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.lock, color: Colors.orange),
            title: Text('Modifier le mot de passe'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showChangePasswordDialog,
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
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
            onTap: _logout,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text(
              'Supprimer mon compte',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le mot de passe'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe actuel',
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrentPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _changePassword();
            },
            child: Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Supprimer le compte'),
          ],
        ),
        content: Text('Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUserAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
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