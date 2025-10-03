import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/supabase_service.dart';

class ExistingUserScreen extends StatefulWidget {
  final VoidCallback onUserFetched;
  const ExistingUserScreen({super.key, required this.onUserFetched});

  @override
  State<ExistingUserScreen> createState() => _ExistingUserScreenState();
}

class _ExistingUserScreenState extends State<ExistingUserScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _fetchUser() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your user name or ID.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First check if the input matches a user_id directly
      bool existsById = await ExpenseSupabaseService.isUserIdTaken(userInput);
      String? actualUserId;

      if (existsById) {
        actualUserId = userInput;
      } else {
        // If not found by user_id, search by user_name
        final users = await ExpenseSupabaseService.getAllUsers();
        for (var user in users) {
          if (user['user_name']?.toString().toLowerCase() == userInput.toLowerCase()) {
            actualUserId = user['user_id']?.toString();
            break;
          }
        }
      }

      if (actualUserId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No user found with that name or ID.';
        });
        return;
      }

      await context.read<UserProvider>().setUserId(actualUserId);
      widget.onUserFetched();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error logging in: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Login as Existing Member'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your existing User ID or Name',
                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'User ID or Name',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _fetchUser,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
