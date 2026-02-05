import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/service_locator.dart';
import '../../features/admin/providers/admin_provider_new.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _clientUsernameController = TextEditingController();
  final _adminUsernameController = TextEditingController();
  bool _isClientLoading = false;
  bool _isAdminLoading = false;
  bool _isCheckingActiveClient = true;

  @override
  void initState() {
    super.initState();
    _checkForActiveClient();
  }

  @override
  void dispose() {
    _clientUsernameController.dispose();
    _adminUsernameController.dispose();
    super.dispose();
  }

  /// Check if there's an active client, if not redirect to admin panel
  Future<void> _checkForActiveClient() async {
    await Future.delayed(const Duration(milliseconds: 300)); // Small delay for UI
    
    final clientAuthService = ServiceLocator.clientAuthService;
    
    // Check if there's an active client authenticated
    if (clientAuthService.isAuthenticated && clientAuthService.currentClientId != null) {
      // There's an active client, navigate to their garden
      if (mounted) {
        context.go('/garden?clientId=${clientAuthService.currentClientId}');
      }
      return;
    }
    
    // No active client found, redirect to admin login
    if (mounted) {
      setState(() {
        _isCheckingActiveClient = false;
      });
      // Navigate to admin login after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          context.go('/admin/login');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking for active client
    if (_isCheckingActiveClient) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_florist,
                size: 100,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(height: 24),
              Text(
                'Красив Двор',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 16),
              Text(
                'Зареждане...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo and title
              const Icon(
                Icons.local_florist,
                size: 100,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(height: 24),
              Text(
                'Красив Двор',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Система за управление на градини',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Client Login Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person,
                              color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Клиентски профил',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clientUsernameController,
                        decoration: const InputDecoration(
                          labelText: 'Потребителско име',
                          prefixIcon: Icon(Icons.account_circle),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Моля въведете потребителско име';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isClientLoading ? null : _handleClientLogin,
                          icon: _isClientLoading
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
                              : const Icon(Icons.login),
                          label: const Text('Вход като клиент'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Admin Login Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.admin_panel_settings,
                              color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Административен панел',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _adminUsernameController,
                        decoration: const InputDecoration(
                          labelText: 'Потребителско име',
                          prefixIcon: Icon(Icons.admin_panel_settings),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Моля въведете потребителско име';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isAdminLoading ? null : _handleAdminLogin,
                          icon: _isAdminLoading
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
                              : const Icon(Icons.admin_panel_settings),
                          label: const Text('Вход като админ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Demo mode button
              TextButton.icon(
                onPressed: _handleDemoMode,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Демо режим'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleClientLogin() async {
    if (_clientUsernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Моля въведете потребителско име')),
      );
      return;
    }

    setState(() {
      _isClientLoading = true;
    });

    try {
      await ServiceLocator.clientAuthService
          .login(_clientUsernameController.text.trim());

      if (!mounted) return;

      setState(() {
        _isClientLoading = false;
      });

      // Navigate directly to the active client's garden
      final clientId = ServiceLocator.clientAuthService.currentClientId;
      if (clientId != null) {
        context.go('/garden?clientId=$clientId');
      } else {
        context.go('/client/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isClientLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Грешка при вход: $e')),
        );
      }
    }
  }

  Future<void> _handleAdminLogin() async {
    if (_adminUsernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Моля въведете потребителско име')),
      );
      return;
    }

    setState(() {
      _isAdminLoading = true;
    });

    try {
      final success = await context
          .read<AdminProvider>()
          .login(_adminUsernameController.text.trim());

      if (!mounted) return;

      setState(() {
        _isAdminLoading = false;
      });

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Невалидно потребителско име')),
        );
        return;
      }

      context.go('/admin-dashboard');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdminLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Грешка при вход: $e')),
        );
      }
    }
  }

  void _handleDemoMode() {
    // Navigate to demo mode
    context.go('/');
  }
}
