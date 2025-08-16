import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'animated_typing_indicator.dart';

class ChatScreenContent extends StatefulWidget {
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
  State<ChatScreenContent> createState() => _ChatScreenContentState();
}

class _ChatScreenContentState extends State<ChatScreenContent> {
  List<Map<String, dynamic>> _messages = [];
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    _listenToMessages();
    widget.textFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(ChatScreenContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentChatId != widget.currentChatId ||
        oldWidget.user?.uid != widget.user?.uid) {
      _subscription?.cancel();
      _messages = [];
      _listenToMessages();
    }

    if (oldWidget.textFocusNode != widget.textFocusNode) {
      oldWidget.textFocusNode.removeListener(_onFocusChange);
      widget.textFocusNode.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    if (widget.textFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), _scrollToEnd);
    }
  }

  void _listenToMessages() {
    if (widget.user == null || widget.currentChatId == null) return;

    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user!.uid)
        .collection('chats')
        .doc(widget.currentChatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _messages = snapshot.docs.map((d) => d.data()).toList();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }, onError: (err) {
      debugPrint('Messages listen error: $err');
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    widget.textFocusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _scrollToEnd() {
    if (widget.scrollController.hasClients) {
      widget.scrollController.animateTo(
        widget.scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Messages area
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: AnimatedOpacity(
                opacity: widget.userName.isNotEmpty ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                child: Text(
                  "Hello, ${widget.userName} 👋",
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
                : ListView.builder(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(10),
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final data = _messages[index];
                bool isUser = data['senderId'] == widget.user?.uid;
                return _ChatMessage(data: data, isUser: isUser);
              },
            ),
          ),

          AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: _buildMinimalistInputArea(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalistInputArea(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey[900]!),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.textController,
                focusNode: widget.textFocusNode,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (value) => widget.onSendMessage(value),
              ),
            ),
            TextButton(
              onPressed: () => widget.onModeChanged('Reply'),
              child: Text(
                'Reply',
                style: TextStyle(
                  color: widget.selectedMode == 'Reply'
                      ? Colors.blueAccent
                      : Colors.grey[400],
                ),
              ),
            ),
            TextButton(
              onPressed: () => widget.onModeChanged('Fix It'),
              child: Text(
                'Fix It',
                style: TextStyle(
                  color: widget.selectedMode == 'Fix It'
                      ? Colors.blueAccent
                      : Colors.grey[400],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: () async {
                if (widget.textController.text.trim().isEmpty) return;
                final tone = await widget.onShowToneSelection(context);
                if (tone != null) {
                  widget.onSendWithGpt(tone);
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

    final bool isGenerating =
        data.containsKey('isGenerating') && data['isGenerating'] == true;

    final messageContent = isGenerating
        ? const AnimatedTypingIndicator()
        : Text(
      data['text'] ?? '',
      style: const TextStyle(color: Colors.white),
    );

    final messageContainer = GestureDetector(
      onLongPress: isGenerating
          ? null
          : () {
        Clipboard.setData(ClipboardData(text: data['text']));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message copied to clipboard')),
        );
      },
      child: Container(
        constraints:
        BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
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
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            avatar,
            const SizedBox(width: 8),
          ],
          Flexible(child: messageContainer),
          if (isUser) ...[
            const SizedBox(width: 8),
            avatar,
          ],
        ],
      ),
    );
  }
}
