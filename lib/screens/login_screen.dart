// This file defines the LoginScreen widget, which handles user authentication and profile setup. It allows users to create a new profile with a PIN and name, or log in using an existing PIN. The screen also supports biometric authentication (Face ID or fingerprint) if available on the device. It uses the local database to store and retrieve user information and navigates to the dashboard upon successful login or setup.
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../main.dart'; // To access global db instance
import '../db/models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSetup = false;
  String _error = '';
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkSetup();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    late bool canCheckBiometrics;
    try {
      canCheckBiometrics =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
    } on PlatformException catch (e) {
      canCheckBiometrics = false;
      print(e);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      setState(() {
        _error = '';
      });
      authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to unlock your Zenith workspace',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        _error = 'Biometric authentication failed or is not set up.';
      });
      return;
    }
    if (!mounted) {
      return;
    }
    if (authenticated) {
      final users = db.getUsers();
      if (users.isNotEmpty) {
        context.go('/dashboard');
      } else {
        setState(() {
          _error = 'No profile found, please setup PIN first.';
        });
      }
    }
  }

  Future<void> _checkSetup() async {
    final users = db.getUsers();
    if (users.isEmpty) {
      if (mounted) setState(() => _isSetup = true);
    }
  }

  void _submit() async {
    if (_pinController.text.length < 4) {
      setState(() => _error = 'Valid PIN (4+ digits) required');
      return;
    }

    if (_isSetup) {
      if (_nameController.text.isEmpty) {
        setState(() => _error = 'Name is required');
        return;
      }
      final user = User(
        name: _nameController.text,
        passwordHash: _pinController.text, // Simplified for local app
        fixedSalary: 1500,
        dutyRatePerHour: 5,
        otRatePerHour: 5,
      );
      await db.putUser(user);
      if (mounted) context.go('/dashboard');
    } else {
      final users = db.getUsers();
      if (users.isNotEmpty && users.first.passwordHash == _pinController.text) {
        if (mounted) context.go('/dashboard');
      } else {
        setState(() => _error = 'Invalid PIN');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A0A0A).withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glyph Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Icon(
                        _isSetup
                            ? Icons.person_add_alt_1_outlined
                            : Icons.fingerprint_outlined,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isSetup ? 'Setup Profile' : 'Welcome to Zenith',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSetup
                          ? 'Create your Zenith workspace'
                          : 'Enter your passkey to continue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    if (_error.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFFF5252)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: const Color(0xFFFF5252), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(_error,
                                    style: const TextStyle(
                                        color: const Color(0xFFFF5252)))),
                          ],
                        ),
                      ),

                    if (_isSetup) ...[
                      _buildTextField(
                        controller: _nameController,
                        label: 'Your Name',
                        icon: Icons.person_outline,
                        isPin: false,
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (!_isSetup && _canCheckBiometrics)
                      InkWell(
                        onTap: _authenticateWithBiometrics,
                        borderRadius: BorderRadius.circular(32),
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.face, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Use Face ID / Biometrics',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500)),
                              ],
                            )),
                      ),

                    if (!_isSetup) const SizedBox(height: 24),

                    _buildTextField(
                      controller: _pinController,
                      label: _isSetup ? 'Create PIN' : 'Enter PIN',
                      icon: Icons.lock_outline,
                      isPin: true,
                      onSubmit: (_) => _submit(),
                    ),

                    const SizedBox(height: 40),

                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0A0A0A),
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(_isSetup ? 'INITIALIZE' : 'UNLOCK',
                          style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 16,
                            letterSpacing: 2.0,
                          )),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isPin,
    Function(String)? onSubmit,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPin,
      keyboardType: isPin ? TextInputType.number : TextInputType.text,
      style: TextStyle(
          color: Colors.white,
          fontSize: isPin ? 24 : 16,
          letterSpacing: isPin ? 8.0 : 1.5,
          fontWeight: isPin ? FontWeight.bold : FontWeight.normal),
      textAlign: isPin ? TextAlign.center : TextAlign.left,
      decoration: InputDecoration(
        labelText: isPin ? null : label,
        hintText: isPin ? label : null,
        hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            letterSpacing: isPin ? 2.0 : 1.0,
            fontSize: 16,
            fontWeight: FontWeight.w300),
        labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.6), letterSpacing: 1.0),
        prefixIcon: isPin
            ? null
            : Icon(icon, color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: const Color(0xFF0A0A0A).withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
        ),
      ),
      onSubmitted: onSubmit,
    );
  }
}
