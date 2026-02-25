import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class ChatScreen extends StatefulWidget {
  final String partnerId;
  const ChatScreen({super.key, required this.partnerId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        // Auto-scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chat with ${widget.partnerId}',
                    style: const TextStyle(fontSize: 16)),
                Text(
                  chatProvider.status,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount:
                      chatProvider.getMessagesFor(widget.partnerId).length,
                  itemBuilder: (context, index) {
                    final message =
                        chatProvider.getMessagesFor(widget.partnerId)[index];
                    return Align(
                      alignment: message.isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: message.isMe
                              ? Colors.blue[100]
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.sender,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(message.text),
                            const SizedBox(height: 4),
                            Text(
                              "${message.timestamp.hour}:${message.timestamp.minute}",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseAnalytics.instance.logEvent(
                          name: 'chat_started', // FIXED TYPO HERE
                          parameters: {'partner_id': widget.partnerId},
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Logged chat_started'),
                              action: SnackBarAction(
                                label: 'Close',
                                onPressed: () {
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                },
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Track Event 1'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        int messageLength = _messageController.text.length;

                        // Example 3: Send multiple events in a loop
                        for (int i = 0; i < 500; i++) {
                          // The `i` variable is your index (0, 1, 2, 3, 4)
                          await FirebaseAnalytics.instance.logEvent(
                            name: 'message_sent',
                            parameters: {
                              'recipient': widget.partnerId,
                              'character_count': messageLength,
                              'loop_iteration': i,
                            },
                          );

                          await FirebaseAnalytics.instance.logEvent(
                            name: 'message_received',
                            parameters: {
                              'sender': widget.partnerId,
                              'character_count': messageLength,
                              'loop_iteration': i,
                            },
                          );
                          await Future.delayed(
                              const Duration(milliseconds: 20));
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Logged 1000 loops of message_sent...'),
                              action: SnackBarAction(
                                label: 'Close',
                                onPressed: () {
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                },
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Track Event 2 (Loop Example)'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            chatProvider.sendMessage(
                                widget.partnerId, value.trim());
                            _messageController.clear();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (_messageController.text.trim().isNotEmpty) {
                          chatProvider.sendMessage(
                              widget.partnerId, _messageController.text.trim());
                          _messageController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
