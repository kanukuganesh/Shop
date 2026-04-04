import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _usernameHintController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordHintController = TextEditingController();
  
  bool _showPassword = false;
  bool _isProcessing = false;

  void _handleSubmit() async {
    if (_isProcessing) return;

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (_usernameController.text.isEmpty || password.isEmpty || _usernameHintController.text.isEmpty || _passwordHintController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields to create account'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Passwords do not match'), backgroundColor: Colors.red.shade600),
      );
      return;
    }
    
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Password must be at least 6 characters'), backgroundColor: Colors.red.shade600),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final auth = context.read<AuthProvider>();
      final success = await auth.signup(
        _usernameController.text,
        password,
        _usernameHintController.text,
        _passwordHintController.text,
      );
      
      if (!mounted) return;
      
      if (success) {
        // Log the user's cart now that they are logged in
        if (mounted) context.read<CartProvider>().loadUserCart(auth.currentUser!.username);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully! Welcome.'), backgroundColor: Colors.green, duration: Duration(seconds: 4)),
        );

        // Immediate field clearing as per advice
        _usernameController.clear();
        _usernameHintController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _passwordHintController.clear();

        setState(() => _isProcessing = false);

        // Timed redirect to Home (1.5 seconds)
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
          if (redirect != null) {
            context.go(redirect);
          } else {
            context.go('/');
          }
        }
        return; 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Username already exists'), backgroundColor: Colors.red.shade600),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade600),
        );
      }
    } finally {
      if (mounted && _isProcessing) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade50, Colors.green.shade100],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      child: const Icon(Icons.energy_savings_leaf, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text('Create Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Join Nagaraju Fruits Shop', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 32),
                    
                    _buildField('Username', 'Choose a username', _usernameController),
                    const SizedBox(height: 16),
                    _buildField('Username Hint', 'e.g., My childhood pet name', _usernameHintController, helperText: 'This will help you remember your username'),
                    const SizedBox(height: 16),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            hintText: 'Create a password',
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: !_showPassword,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Confirm your password',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildField('Password Hint', 'e.g., Summer 2024 trip', _passwordHintController, helperText: 'This will help you recover your password'),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isProcessing 
                          ? const SizedBox(
                              height: 24, 
                              width: 24, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                            )
                          : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ', style: TextStyle(color: Colors.grey.shade600)),
                        InkWell(
                          onTap: () => context.go('/login'),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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

  Widget _buildField(String label, String hint, TextEditingController controller, {String? helperText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: hint,
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(helperText, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ],
    );
  }
}
