import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';

class SARChatScreen extends StatefulWidget {
  final String sarMemberId;
  final String userId;
  final String userName;

  const SARChatScreen({
    super.key,
    required this.sarMemberId,
    required this.userId,
    required this.userName,
  });

  @override
  State<SARChatScreen> createState() => _SARChatScreenState();
}

class _SARChatScreenState extends State<SARChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _chatService.initialize();
    _chatService.setMessageReceivedCallback((msg) {
      if (msg.chatId == _chatId()) {
        setState(() {
          _messages.add(msg);
        });
        _showNotification(msg);
      }
    });
  }

  String _chatId() => '${widget.sarMemberId}_${widget.userId}';

  Future<void> _loadMessages() async {
    setState(() {
      _messages = _chatService.getMessagesForChat(_chatId());
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await _chatService.sendMessage(
      chatId: _chatId(),
      content: text,
      type: MessageType.text,
      priority: MessagePriority.normal,
    );
    _controller.clear();
    _loadMessages();
  }

  void _showNotification(ChatMessage msg) {
    // TODO: Integrate with NotificationService for local push notification
    // NotificationService().showNotification(msg.content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SAR Chat with ${widget.userName}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ListTile(
                  title: Text(msg.senderName),
                  subtitle: Text(msg.content),
                  trailing: Text(
                    msg.timestamp.toLocal().toString().substring(0, 16),
                    style: TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                    ),
                  ),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
