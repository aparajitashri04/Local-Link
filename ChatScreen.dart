import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

typedef MessageReceivedCallback = void Function(Message message);

// ---------------------------
// 1. MESSAGE MODEL
// ---------------------------
class Message {
  final String senderId;
  final String senderName;
  final String text;
  final DateTime time;
  final String senderIp;

  Message({
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.time,
    required this.senderIp,
  });

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'senderName': senderName,
    'text': text,
    'timestamp': time.millisecondsSinceEpoch,
    'senderIp': senderIp,
  };

  factory Message.fromMap(Map<dynamic, dynamic> map) {
    return Message(
      senderId: map['senderId'] ?? 'N/A',
      senderName: map['senderName'] ?? 'Unknown',
      text: map['text'] ?? '',
      time: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      senderIp: map['senderIp'] ?? '0.0.0.0',
    );
  }

  factory Message.fromJson(String jsonStr) {
    return Message.fromMap(json.decode(jsonStr));
  }

  String toJson() => json.encode(toMap());
}

// ---------------------------
// 2. UDP SERVICE
// ---------------------------
class UDPService {
  final int port;
  late RawDatagramSocket _socket;
  final String currentUserId;
  final String currentUserName;
  final String currentUserIp;
  MessageReceivedCallback? onMessage;

  UDPService({
    this.port = 5000,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserIp,
  });

  Future<void> startListening() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    _socket.broadcastEnabled = true;

    _socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket.receive();
        if (datagram != null) {
          try {
            final msg = Message.fromJson(utf8.decode(datagram.data));
            if (msg.senderId != currentUserId) {
              onMessage?.call(msg);
            }
          } catch (_) {}
        }
      }
    });
  }

  void sendMessage(String text) {
    final message = Message(
      senderId: currentUserId,
      senderName: currentUserName,
      text: text,
      time: DateTime.now(),
      senderIp: currentUserIp,
    );

    final data = utf8.encode(message.toJson());
    _socket.send(data, InternetAddress('255.255.255.255'), port);

    onMessage?.call(message); // locally add own message
  }

  void close() => _socket.close();
}

// ---------------------------
// 3. CHAT SCREEN
// ---------------------------
class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String currentUserIP;
  final String peerName;
  final String peerUserId;
  final String peerIP;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserIP,
    required this.peerName,
    required this.peerUserId,
    required this.peerIP,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Message> _messages = [];
  late UDPService _udpService;
  late DatabaseReference _firebaseRef;

  @override
  void initState() {
    super.initState();

    // Firebase reference for optional persistence
    _firebaseRef = FirebaseDatabase.instance.ref('group_chats');

    // Initialize UDP service
    _udpService = UDPService(
      currentUserId: widget.currentUserId,
      currentUserName: widget.currentUserName,
      currentUserIp: widget.currentUserIP,
    );

    _udpService.onMessage = (message) {
      setState(() {
        _messages.insert(0, message);
      });
      _saveToFirebase(message);
    };

    _udpService.startListening();
  }

  void _saveToFirebase(Message message) async {
    try {
      await _firebaseRef.push().set(message.toMap());
    } catch (e) {
      print('Failed to save message: $e');
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    _udpService.sendMessage(text);
  }

  @override
  void dispose() {
    _udpService.close();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerName),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg.senderId == widget.currentUserId;
                return _buildMessageTile(msg, isMe);
              },
            ),
          ),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageTile(Message msg, bool isMe) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMe ? Colors.green.shade100 : Colors.grey.shade300;
    final radius = BorderRadius.circular(15);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Align(
        alignment: alignment,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: isMe
                ? radius.copyWith(bottomRight: Radius.zero)
                : radius.copyWith(bottomLeft: Radius.zero),
          ),
          child: Column(
            crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text('${msg.senderName}: ${msg.text}'),
              const SizedBox(height: 4),
              Text(
                '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade200,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo, color: Colors.blue),
            onPressed: () {
              // TODO: Open gallery or camera
            },
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: () => _sendMessage(_textController.text),
          ),
        ],
      ),
    );
  }
}



