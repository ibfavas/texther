import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'animated_typing_indicator.dart';

class ChatScreenContent extends StatelessWidget {
  final User? user;
  final String userName;
  final String? currentChatId;
  final ScrollController scrollController;
  final TextEditingController textController;
  final String selectedMode;
  final Function(String) onModeChanged;
  final Function(String) onSendWithGpt;
  final Future<String?> Function(BuildContext) onShowToneSelection;
  final Function(String) onSendMessage;
  final FocusNode textFocusNode;

  const ChatScreenContent({
    super.key,
    required this.user,
    required this.userName,
    required this.currentChatId,
    required this.scrollController,
    required this.textController,
    required this.selectedMode,
    required this.onModeChanged,
    required this.onSendWithGpt,
    required this.onShowToneSelection,
    required this.onSendMessage,
    required this.textFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: currentChatId == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .collection('chats')
                .doc(currentChatId)
                .collection('messages')
                .orderBy('timestamp')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "Hello, $userName 👋",
                    style: const TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                );
              }
              final messages = snapshot.data!.docs;
              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(10),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final document = messages[index];
                  Map<String, dynamic> data =
                  document.data()! as Map<String, dynamic>;
                  bool isUser = data['senderId'] == user?.uid;
                  return _ChatMessage(data: data, isUser: isUser);
                },
              );
            },
          ),
        ),
        _buildMinimalistInputArea(context),
      ],
    );
  }

  Widget _buildMinimalistInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: 8.0,
        right: 8.0,
        bottom: 8.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey[800]!),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                focusNode: textFocusNode,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                onSubmitted: onSendMessage,
              ),
            ),
            TextButton(
              onPressed: () => onModeChanged('Reply'),
              child: Text(
                'Reply',
                style: TextStyle(
                  color: selectedMode == 'Reply'
                      ? Colors.blueAccent
                      : Colors.grey[400],
                ),
              ),
            ),
            TextButton(
              onPressed: () => onModeChanged('Fix It'),
              child: Text(
                'Fix It',
                style: TextStyle(
                  color: selectedMode == 'Fix It'
                      ? Colors.blueAccent
                      : Colors.grey[400],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: () async {
                if (textController.text.trim().isEmpty) return;
                final tone = await onShowToneSelection(context);
                if (tone != null) {
                  onSendWithGpt(tone);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isUser;

  const _ChatMessage({
    required this.data,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      backgroundColor: isUser ? Colors.grey[900] : Colors.white10,
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        color: Colors.white,
        size: 20,
      ),
    );

    final bool isGenerating = data.containsKey('isGenerating') && data['isGenerating'];

    final messageContent = isGenerating
        ? const AnimatedTypingIndicator()
        : Text(
      data['text'],
      style: const TextStyle(color: Colors.white),
    );

    final messageContainer = GestureDetector(
      onLongPress: isGenerating ? null : () {
        Clipboard.setData(ClipboardData(text: data['text']));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message copied to clipboard')),
        );
      },
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[850],
          borderRadius: BorderRadius.circular(14),
        ),
        child: messageContent,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            avatar,
            const SizedBox(width: 8),
          ],
          Flexible(
            child: messageContainer,
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            avatar,
          ],
        ],
      ),
    );
  }
}