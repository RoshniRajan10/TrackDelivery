import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_provider.dart';
import 'chat_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRole = 'customer';

  final List<String> _roles = ['customer', 'delivery_boy'];

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleConnect() {
    if (_idController.text.isNotEmpty) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final myId = _idController.text.trim();

      chatProvider.connect(myId, _selectedRole);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ChatListScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an ID')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery System Login'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'ID (Required, e.g., C001 or DB001)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              items: _roles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role == 'customer' ? 'Customer' : 'Delivery Boy'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleConnect,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Connect & Start Chat'),
            ),
          ],
        ),
      ),
    );
  }
}
