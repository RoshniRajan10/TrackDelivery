import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatMessage {
  final String text;
  final String sender;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.isMe,
    required this.timestamp,
  });
}

class ChatProvider with ChangeNotifier {
  WebSocketChannel? _channel;
  final Map<String, List<ChatMessage>> _messages = {};
  String _status = 'Disconnected';
  String? _myId;
  String? _role;

  // Replace with your actual server URL (use appropriate IP for physical device)
  // For Android emulator use 10.0.2.2, for iOS simulator use localhost
  // final String _serverUrl = 'ws://localhost:8000';
  String get _serverUrl => dotenv.env['SERVER_URL'] ?? 'ws://localhost:8000';
  List<String> get activePartners => _messages.keys.toList();
  List<ChatMessage> getMessagesFor(String partnerId) =>
      _messages[partnerId] ?? [];
  String get status => _status;
  String? get myId => _myId;
  String? get role => _role;

  void connect(String id, String role) {
    if (_channel != null) {
      _channel!.sink.close();
    }

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      _status = 'Connecting...';
      _myId = id;
      _role = role;
      notifyListeners();

      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          _status = 'Error: $error';
          notifyListeners();
        },
        onDone: () {
          _status = 'Disconnected';
          notifyListeners();
        },
      );

      // Register immediately after connection
      _register(id, role);
    } catch (e) {
      _status = 'Connection Failed: $e';
      notifyListeners();
    }
  }

  void _register(String id, String role) {
    final message = jsonEncode({
      'type': 'register',
      'role': role,
      'id': id,
    });
    _channel?.sink.add(message);
  }

  void pair(String myId, String partnerId) {
    if (_channel != null) {
      // The backend expects 'customerId' and 'deliveryBoyId'
      // We need to determine which is which based on our role, or just send both if we know.
      // However, the backend pair.js example sends:
      // { type: 'pair', customerId: 'C001', deliveryBoyId: 'DB001' }
      // It doesn't seem to care who sends it, just that the mapping is created.
      // So we need to know who is who.

      String cId = '';
      String dbId = '';

      if (_role == 'customer') {
        cId = myId;
        dbId = partnerId;
      } else {
        cId = partnerId;
        dbId = myId;
      }

      if (!_messages.containsKey(partnerId)) {
        _messages[partnerId] = [];
        notifyListeners();
      }

      final message = jsonEncode({
        'type': 'pair',
        'customerId': cId,
        'deliveryBoyId': dbId,
        'channelId': '$dbId-$cId', // Deterministic unique channel for this pair
      });
      _channel?.sink.add(message);
    }
  }

  void sendMessage(String partnerId, String text) {
    if (_channel != null && text.isNotEmpty) {
      String cId = '';
      String dbId = '';

      if (_role == 'customer') {
        cId = _myId ?? '';
        dbId = partnerId;
      } else {
        cId = partnerId;
        dbId = _myId ?? '';
      }

      final message = jsonEncode({
        'type': 'message',
        'to': partnerId,
        'channelId': '$dbId-$cId',
        'text': text,
      });
      _channel?.sink.add(message);

      // Add to local list immediately for UI responsiveness
      if (!_messages.containsKey(partnerId)) {
        _messages[partnerId] = [];
      }
      _messages[partnerId]!.add(ChatMessage(
        text: text,
        sender: 'Me',
        isMe: true,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final parsed = jsonDecode(data);
      final type = parsed['type'];

      switch (type) {
        case 'registered':
          _status = 'Registered as $_role';
          notifyListeners();
          break;
        case 'paired':
          if (parsed['message'] != null) {
            final msg = parsed['message'] as String;
            _status = msg;
          }
          notifyListeners();
          break;
        case 'message':
          final from = parsed['from'] ?? 'Unknown';
          if (!_messages.containsKey(from)) {
            _messages[from] = [];
          }
          _messages[from]!.add(ChatMessage(
            text: parsed['text'],
            sender: from,
            isMe: false,
            timestamp: DateTime.now(), // or parse parsed['timestamp']
          ));
          notifyListeners();
          break;
        case 'error':
          // We'll just update status instead of mixing errors into messages
          _status = 'Error: ${parsed['message']}';
          notifyListeners();
          break;
        case 'location_update':
          // Optionally handle location updates if needed in chat
          break;
      }
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
