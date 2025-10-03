import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'existing_user_screen.dart';
import 'register_user_screen.dart';

class UserSelectorScreen extends StatefulWidget {
  final VoidCallback onUserSelected;
  const UserSelectorScreen({super.key, required this.onUserSelected});

  @override
  State<UserSelectorScreen> createState() => _UserSelectorScreenState();
}

class _UserSelectorScreenState extends State<UserSelectorScreen> {
  List<dynamic> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final users = await userProvider.getAllUsers();
      setState(() {
        _users = users;
      });
    } catch (e) {
      // Handle error silently for now
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToExistingUser() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExistingUserScreen(
          onUserFetched: widget.onUserSelected,
        ),
      ),
    );
  }

  void _navigateToRegisterUser() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RegisterUserScreen(
          onRegistered: widget.onUserSelected,
        ),
      ),
    );
  }

  Future<void> _selectUser(dynamic user) async {
    final userProvider = context.read<UserProvider>();
    final success = await userProvider.loginWithUserId(user.id);
    if (success) {
      widget.onUserSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'Select User',
                style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose an existing user or create a new account',
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Existing Users List
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else if (_users.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Existing Users',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return Card(
                              color: const Color(0xFF2A2A2A),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    user.userName[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  user.userName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'ID: ${user.id}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                                onTap: () => _selectUser(user),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 64, color: Colors.white54),
                        const SizedBox(height: 16),
                        const Text(
                          'No users found',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create your first account to get started',
                          style: TextStyle(fontSize: 14, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _navigateToRegisterUser,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Create New Account'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _navigateToExistingUser,
                      icon: const Icon(Icons.login),
                      label: const Text('Sign In with Username'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
