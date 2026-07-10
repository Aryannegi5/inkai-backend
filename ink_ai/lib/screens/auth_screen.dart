import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'design_source_screen.dart';
import 'onboarding_flow.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _AuthForm(),
        ),
      ),
    );
  }
}

class _AuthForm extends StatefulWidget {
  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm>
    with SingleTickerProviderStateMixin {
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.value = 1.0;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _fadeController.reverse().then((_) {
      setState(() {
        _isLoginMode = !_isLoginMode;
        _formKey.currentState?.reset();
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
      });
      _fadeController.forward();
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    if (!_isLoginMode &&
        _passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const DesignSourceScreen()),
          (route) => false,
        );
      } else {
        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          'uid': cred.user!.uid,
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const OnboardingFlow()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Authentication failed. Please try again.');
    } catch (e) {
      _showError(
          'Connection error. Please check your internet and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFD9383A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isLoginMode ? 'Welcome back!' : 'Sign up',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isLoginMode
                ? 'Sign in to access your designs'
                : 'Create an account to get started',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Color(0xFF7E7E7E),
            ),
          ),
          const SizedBox(height: 48),
          Form(
            key: _formKey,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _isLoginMode
                  ? _buildLoginForm()
                  : _buildSignupForm(),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: PhysicalModel(
              color: Colors.transparent,
              elevation: 6,
              shadowColor: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: MaterialButton(
                  onPressed: _isLoading ? null : _submit,
                  height: 54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  color: const Color(0xFF000000),
                  disabledColor: const Color(0xFF000000).withValues(alpha: 0.5),
                  elevation: 0,
                  highlightElevation: 0,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isLoginMode ? 'Sign In' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: GestureDetector(
              onTap: _isLoading ? null : _toggleMode,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Color(0xFFD9383A),
                  ),
                  children: [
                    TextSpan(
                      text: _isLoginMode ? 'REGISTER' : 'LOGIN',
                    ),
                    const TextSpan(text: '  >'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      children: [
        _buildField(
          controller: _emailController,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: _validateEmail,
        ),
        const SizedBox(height: 28),
        _buildField(
          controller: _passwordController,
          label: 'Password',
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          validator: _validatePassword,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off
                  : Icons.visibility,
              size: 20,
              color: const Color(0xFF7E7E7E),
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              final email = _emailController.text.trim();
              if (email.isEmpty) {
                _showError(
                    'Enter your email first to reset your password');
                return;
              }
              FirebaseAuth.instance.sendPasswordResetEmail(email: email);
              _showError('Password reset link sent to $email');
            },
            child: const Text(
              'FORGOT PASSWORD?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Color(0xFFD9383A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      key: const ValueKey('signup'),
      children: [
        _buildField(
          controller: _nameController,
          label: 'Full Name',
          textInputAction: TextInputAction.next,
          validator: _validateName,
        ),
        const SizedBox(height: 28),
        _buildField(
          controller: _emailController,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: _validateEmail,
        ),
        const SizedBox(height: 28),
        _buildField(
          controller: _passwordController,
          label: 'Password',
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          validator: _validatePassword,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off
                  : Icons.visibility,
              size: 20,
              color: const Color(0xFF7E7E7E),
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 28),
        _buildField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
          suffix: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_off
                  : Icons.visibility,
              size: 20,
              color: const Color(0xFF7E7E7E),
            ),
            onPressed: () =>
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF111111),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 10),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE5E5E5), width: 1),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE5E5E5), width: 1),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF111111), width: 1.5),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD9383A), width: 1),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD9383A), width: 1.5),
            ),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: suffix,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
