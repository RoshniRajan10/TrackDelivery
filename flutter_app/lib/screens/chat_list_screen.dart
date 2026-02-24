import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_provider.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _partnerIdController = TextEditingController();

  void _startNewChat(BuildContext context, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start New Chat'),
          content: TextField(
            controller: _partnerIdController,
            decoration: const InputDecoration(
              labelText: 'Enter Partner ID',
              hintText: 'e.g., DB001 or c1',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final partnerId = _partnerIdController.text.trim();
                final role = chatProvider.role;

                if (partnerId.isNotEmpty) {
                  if (role == 'customer' && partnerId.toLowerCase().startsWith('c')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Customers can only chat with Delivery Boys.')),
                    );
                    return;
                  } else if (role == 'delivery_boy' && partnerId.toLowerCase().startsWith('db')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Delivery Boys can only chat with Customers.')),
                    );
                    return;
                  }

                  // Instruct provider to create channel and send pair request
                  chatProvider.pair(chatProvider.myId ?? '', partnerId);
                  
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(partnerId: partnerId),
                    ),
                  );
                }
              },
              child: const Text('Start'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final activePartners = chatProvider.activePartners;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chats'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: activePartners.isEmpty
              ? const Center(child: Text('No active chats. Start a new one!'))
              : ListView.builder(
                  itemCount: activePartners.length,
                  itemBuilder: (context, index) {
                    final partnerId = activePartners[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(partnerId[0].toUpperCase()),
                      ),
                      title: Text(partnerId),
                      subtitle: const Text('Tap to open chat'),
                      onTap: () {
                        chatProvider.pair(chatProvider.myId ?? '', partnerId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(partnerId: partnerId),
                          ),
                        );
                      },
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _startNewChat(context, chatProvider),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
