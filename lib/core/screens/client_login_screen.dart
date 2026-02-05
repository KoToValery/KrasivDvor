import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/service_locator.dart';
import '../services/client_auth_service.dart';

class ClientLoginScreen extends StatefulWidget {
  const ClientLoginScreen({super.key});

  @override
  State<ClientLoginScreen> createState() => _ClientLoginScreenState();
}

class _ClientLoginScreenState extends State<ClientLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo and title
              const Icon(
                Icons.local_florist,
                size: 80,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(height: 24),
              Text(
                'Клиентски профил',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Влезте в своя профил',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Login form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Потребителско име',
                        prefixIcon: Icon(Icons.person),
                        hintText: 'Въведете вашето потребителско име',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Моля въведете потребителско име';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Вход'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  // Navigate to main app for demo
                  context.go('/');
                },
                child: const Text('Продължи без вход'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final username = _usernameController.text.trim();

      print('DEBUG: Attempting login with username: $username');

      final authService = ServiceLocator.clientAuthService;
      final result = await authService.login(username);

      print('DEBUG: Login successful for client: ${result.user['name']}');
      print('DEBUG: Client ID: ${authService.currentClientId}');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navigate to client dashboard
        print('DEBUG: Navigating to client dashboard');
        context.go('/client/dashboard');
      }
    } catch (e) {
      print('DEBUG: Login failed with error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Грешка при вход: $e')),
        );
      }
    }
  }
}
