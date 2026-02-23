import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'Password_service.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String peerUserId;
  final String peerName;
  final String networkId;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.peerUserId,
    required this.peerName,
    required this.networkId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool _isSending = false;
  bool _peerIsTyping = false;

  late DatabaseReference _messagesRef;
  late DatabaseReference _typingRef;
  late String _chatId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _typingRef.child(widget.currentUserId).set(false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initChat() {
    final a = widget.currentUserId;
    final b = widget.peerUserId;

    _chatId = a.compareTo(b) < 0 ? 'chat_${a}_$b' : 'chat_${b}_$a';

    _messagesRef = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app,
      databaseURL: 'https://local-link-63f75-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('CHATS')
        .child(_chatId)
        .child('messages');

    _typingRef = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app,
      databaseURL: 'https://local-link-63f75-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('CHATS')
        .child(_chatId)
        .child('typing');

    _messagesRef.onChildAdded.listen(_handleIncomingMessage);
    _typingRef.child(widget.peerUserId).onValue.listen((event) {
      if (mounted) {
        setState(() {
          _peerIsTyping = event.snapshot.value == true;
        });
      }
    });
  }

  Future<void> _handleIncomingMessage(DatabaseEvent event) async {
    if (event.snapshot.value == null) return;

    final data = Map<String, dynamic>.from(event.snapshot.value as Map);

    final key = await PasswordService.sessionKeyFromUsers(
      widget.currentUserId,
      widget.peerUserId,
    );

    final decrypted = await PasswordService.decryptMessage(data['message'], key);

    setState(() {
      _messages.add({
        'senderId': data['senderId'],
        'senderName': data['senderName'],
        'message': decrypted,
        'timestamp': data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      });
    });

    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();
    _typingRef.child(widget.currentUserId).set(false);

    try {
      final key = await PasswordService.sessionKeyFromUsers(
        widget.currentUserId,
        widget.peerUserId,
      );

      final encrypted = await PasswordService.encryptMessage(text, key);

      await _messagesRef.push().set({
        'senderId': widget.currentUserId,
        'senderName': widget.currentUserName,
        'message': encrypted,
        'timestamp': ServerValue.timestamp,
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2F33),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => _TypingDot(delay: i * 200)),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Color _getAvatarColor(String userId) {
    final colors = [
      const Color(0xFF06B6D4),
      const Color(0xFF14B8A6),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    final hash = userId.hashCode.abs();
    return colors[hash % colors.length];
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isMe = msg['senderId'] == widget.currentUserId;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(isMe ? 20 * (1 - value) : -20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF14B8A6)],
                  )
                      : null,
                  color: isMe ? null : const Color(0xFF2C2F33),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  msg['message'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202225),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F33),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getAvatarColor(widget.peerUserId),
                    _getAvatarColor(widget.peerUserId).withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(widget.peerName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.peerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _peerIsTyping ? 'typing...' : 'Online',
                        style: TextStyle(
                          color: _peerIsTyping ? const Color(0xFF06B6D4) : const Color(0xFF99AAB5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C2F33),
              Color(0xFF202225),
              Color(0xFF23272A),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty && !_peerIsTyping
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2C2F33),
                        border: Border.all(
                          color: const Color(0xFF40444B),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Color(0xFF72767D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No messages yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start the conversation!',
                      style: TextStyle(
                        color: Color(0xFF99AAB5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
                  : _messages.isEmpty && _peerIsTyping
                  ? ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [_buildTypingIndicator()],
              )
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _messages.length + (_peerIsTyping ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _messages.length) return _buildTypingIndicator();
                  return _buildMessage(_messages[i]);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF2C2F33),
                border: Border(
                  top: BorderSide(
                    color: Color(0xFF40444B),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF202225),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF40444B),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: null,
                          onChanged: (value) {
                            _typingRef.child(widget.currentUserId).set(value.isNotEmpty);
                          },
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: Color(0xFF72767D)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: _isSending
                            ? const LinearGradient(
                          colors: [Color(0xFF40444B), Color(0xFF40444B)],
                        )
                            : const LinearGradient(
                          colors: [Color(0xFF06B6D4), Color(0xFF14B8A6)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: _isSending ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        transform: Matrix4.translationValues(0, _animation.value, 0),
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF99AAB5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}