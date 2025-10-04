import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'user_selector_screen.dart';

class ExistingUserScreen extends StatefulWidget {
  final VoidCallback onUserFetched;
  const ExistingUserScreen({super.key, required this.onUserFetched});

  @override
  State<ExistingUserScreen> createState() => _ExistingUserScreenState();
}

class _ExistingUserScreenState extends State<ExistingUserScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;
  int _welcomeBackTapCount = 0;

  Future<void> _loginUser() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your username.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final userProvider = context.read<UserProvider>();
    
    // Try to login with username
    final success = await userProvider.loginWithUsername(userInput);

    if (success) {
      // Pop this screen first before calling callback
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      // Then call the callback to trigger AuthWrapper rebuild
      widget.onUserFetched();
    } else {
      setState(() {
        _errorMessage = userProvider.errorMessage ?? 'Login failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _welcomeBackTapCount++;
                  });
                  debugPrint('🔍 Welcome Back tapped: $_welcomeBackTapCount times');
                  
                  // If tapped 7 or more times, show existing users screen
                  if (_welcomeBackTapCount >= 7) {
                    debugPrint('🎯 Welcome Back tapped 7+ times - showing existing users');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserSelectorScreen(
                          onUserSelected: () {
                            widget.onUserFetched();
                          },
                        ),
                      ),
                    );
                    // Reset counter
                    _welcomeBackTapCount = 0;
                  }
                },
                child: const Text(
                  'Welcome Back',
                  style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your username to continue',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter your username',
                  hintStyle: const TextStyle(color: Colors.grey),
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.white70),
                ),
                onSubmitted: (_) => _loginUser(),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: userProvider.isLoading ? null : _loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: userProvider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
