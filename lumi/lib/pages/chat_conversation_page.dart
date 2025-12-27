import 'package:flutter/material.dart';

class ChatConversationPage extends StatefulWidget {
  final int sessionId;
  
  const ChatConversationPage({super.key, required this.sessionId});

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Chat Conversation Page - Session ID: ${widget.sessionId}'),
      ),
    );
  }
}

