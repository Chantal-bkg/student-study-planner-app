import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart';

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isHovering = false;

  // Couleurs du thème
  final Color _primaryColor = const Color(0xFF3498DB);
  final Color _accentColor = const Color(0xFF2ECC71);
  final Color _warningColor = const Color(0xFFF39C12);
  final Color _darkColor = const Color(0xFF2C3E50);

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final uri = Uri.parse('http://10.0.2.2:5002/api/auth/register');
        print("Envoi à: $uri");

        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': _fullNameController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 201) {
          // Succès...
        } else if (response.statusCode == 400) {
          _showErrorDialog('Email déjà utilisé');
        } else {
          _showErrorDialog('Erreur serveur: ${response.statusCode}');
        }
      } on SocketException {
        _showErrorDialog('Pas de connexion internet');
      } on TimeoutException {
        _showErrorDialog('Temps d\'attente dépassé');
      } on http.ClientException catch (e) {
        _showErrorDialog('Erreur client: ${e.message}');
      } catch (e) {
        _showErrorDialog('Erreur inattendue: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erreur d\'inscription'),
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

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre nom complet';
    }
    if (value.trim().split(' ').length < 2) {
      return 'Veuillez entrer votre prénom et nom';
    }
    if (value.length < 3) {
      return 'Le nom doit contenir au moins 3 caractères';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre email';
    }
    if (!RegExp(r'^[\w-\.]+@(etu\.[\w-]+\.\w+|[\w-]+\.\w+)$').hasMatch(value)) {
      return 'Veuillez entrer un email étudiant valide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Doit contenir majuscule, minuscule et chiffre';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
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
              constraints: const BoxConstraints(maxWidth: 450),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animation de livre
                    _buildBookAnimation(),
                    const SizedBox(height: 30),

                    // Titre
                    Text(
                      'Créer un Compte Étudiant',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _darkColor,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Rejoignez notre communauté académique',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Champ Nom complet
                    _buildInputField(
                      controller: _fullNameController,
                      hint: 'Nom complet',
                      icon: Icons.person_outline,
                      validator: _validateFullName,
                    ),
                    const SizedBox(height: 20),

                    // Champ Email
                    _buildInputField(
                      controller: _emailController,
                      hint: 'Email étudiant',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),

                    // Champ Mot de passe
                    _buildPasswordField(
                      controller: _passwordController,
                      hint: 'Mot de passe',
                      isVisible: _isPasswordVisible,
                      onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 20),

                    // Champ Confirmer mot de passe
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      hint: 'Confirmer mot de passe',
                      isVisible: _isConfirmPasswordVisible,
                      onToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 30),

                    // Indicateur de force du mot de passe
                    _buildPasswordStrengthIndicator(),
                    const SizedBox(height: 20),

                    // Bouton de création de compte
                    _buildSignupButton(),
                    const SizedBox(height: 30),

                    // Ligne de séparation
                    _buildDivider(),
                    const SizedBox(height: 20),

                    // Lien vers la page de connexion
                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookAnimation() {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: _primaryColor.withOpacity(0.2),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Livre ouvert
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            width: 75,
            height: 55,
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _darkColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Pages du livre
                Positioned(
                  left: 37,
                  top: 5,
                  child: Container(
                    width: 1,
                    height: 45,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                // Lignes de texte à gauche
                ...List.generate(5, (index) => Positioned(
                  left: 10,
                  top: 10 + (index * 8.0),
                  child: Container(
                    width: 22,
                    height: 2,
                    color: Colors.white.withOpacity(0.8),
                  ),
                )),
                // Lignes de texte à droite
                ...List.generate(5, (index) => Positioned(
                  right: 10,
                  top: 10 + (index * 8.0),
                  child: Container(
                    width: 22,
                    height: 2,
                    color: Colors.white.withOpacity(0.8),
                  ),
                )),
              ],
            ),
          ),

          // Chapeau de graduation
          Positioned(
            top: 8,
            right: 12,
            child: Container(
              width: 35,
              height: 22,
              decoration: BoxDecoration(
                color: _darkColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -3,
                    right: 9,
                    child: Container(
                      width: 1,
                      height: 12,
                      color: _warningColor,
                    ),
                  ),
                  Positioned(
                    top: 7,
                    right: 6,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _warningColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Étoile de nouveau compte
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: _accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.words,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        prefixIcon: Icon(icon, color: _primaryColor),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: _primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        prefixIcon: Icon(Icons.lock_outline, color: _primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: _primaryColor,
          ),
          onPressed: onToggle,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: _primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Force du mot de passe:',
          style: TextStyle(
            color: _darkColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: _passwordController.text.length / 16,
                backgroundColor: Colors.grey.shade300,
                color: _passwordController.text.length > 10
                    ? _accentColor
                    : _passwordController.text.length > 6
                    ? _warningColor
                    : Colors.red,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _passwordController.text.isEmpty
                  ? ''
                  : _passwordController.text.length > 10
                  ? 'Fort'
                  : _passwordController.text.length > 6
                  ? 'Moyen'
                  : 'Faible',
              style: TextStyle(
                color: _passwordController.text.isEmpty
                    ? Colors.grey
                    : _passwordController.text.length > 10
                    ? _accentColor
                    : _passwordController.text.length > 6
                    ? _warningColor
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '• 8 caractères minimum\n• 1 majuscule et 1 minuscule\n• 1 chiffre',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _accentColor,
              _accentColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: _isHovering
              ? [
            BoxShadow(
              color: _accentColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleSignup,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
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
              : Text(
            'Créer mon compte',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey.shade300,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Déjà membre ?',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey.shade300,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return TextButton(
      onPressed: _isLoading
          ? null
          : () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StudentLoginPage()),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text.rich(
        TextSpan(
          text: 'Connectez-vous ',
          style: TextStyle(
            color: _darkColor,
            fontSize: 16,
          ),
          children: [
            TextSpan(
              text: 'ici',
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}