import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/supabase_service.dart';
import 'existing_user_screen.dart';

class UserSelectorScreen extends StatefulWidget {
  final VoidCallback onUserSelected;
  const UserSelectorScreen({super.key, required this.onUserSelected});

  @override
  State<UserSelectorScreen> createState() => _UserSelectorScreenState();
}

class _UserSelectorScreenState extends State<UserSelectorScreen> {
  final TextEditingController _controller = TextEditingController();

  void _navigateToExistingUser() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExistingUserScreen(
          onUserFetched: widget.onUserSelected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your User ID',
                style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
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
              ElevatedButton(
                onPressed: () async {
                  final userId = _controller.text.trim();
                  if (userId.isNotEmpty) {
                    final isTaken = await ExpenseSupabaseService.isUserIdTaken(userId);
                    if (isTaken) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This user name is already taken. Please choose another.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    await context.read<UserProvider>().setUserId(userId);
                    widget.onUserSelected();
                  }
                },
                child: const Text('Continue'),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _navigateToExistingUser,
                child: const Text(
                  'Already a member?',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
