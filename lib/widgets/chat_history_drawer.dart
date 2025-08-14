import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatHistoryDrawer extends StatelessWidget {
  final User? user;
  final List<DocumentSnapshot> chatHistoryDocs;
  final String? currentChatId;
  final Function(String) onChatSelected;
  final VoidCallback onNewChat;
  final Function(String) onDeleteChat;

  const ChatHistoryDrawer({
    super.key,
    required this.user,
    required this.chatHistoryDocs,
    required this.currentChatId,
    required this.onChatSelected,
    required this.onNewChat,
    required this.onDeleteChat,
  });

  @override
  Widget build(BuildContext context) {
    final replyChats = chatHistoryDocs.where((doc) =>
    (doc.data() as Map<String, dynamic>).containsKey('lastMode') &&
        doc['lastMode'] == 'Reply').toList();
    final fixItChats = chatHistoryDocs.where((doc) =>
    (doc.data() as Map<String, dynamic>).containsKey('lastMode') &&
        doc['lastMode'] == 'Fix It').toList();

    return Drawer(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("CHAT HISTORY",
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.white),
              title: const Text('New Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onTap: onNewChat,
            ),
            const Divider(color: Colors.grey),
            Expanded(
              child: ListView(
                children: [
                  if (replyChats.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text("💬 Reply Chats", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    ),
                  ...replyChats.map((doc) => _ChatTile(
                    doc: doc,
                    onTap: onChatSelected,
                    onDelete: (chatId) {
                      if (chatId == currentChatId) {
                        onNewChat();
                      }
                      onDeleteChat(chatId);
                    },
                  )),
                  if (fixItChats.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text("🛠 Fix It Chats", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    ),
                  ...fixItChats.map((doc) => _ChatTile(
                    doc: doc,
                    onTap: onChatSelected,
                    onDelete: (chatId) {
                      if (chatId == currentChatId) {
                        onNewChat();
                      }
                      onDeleteChat(chatId);
                    },
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final DocumentSnapshot doc;
  final Function(String) onTap;
  final Function(String) onDelete;

  const _ChatTile({
    required this.doc,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[400],
        child: Text(data['title'] != null && data['title'].isNotEmpty
            ? data['title'][0].toUpperCase()
            : '?',
          style: const TextStyle(color: Colors.black),
        ),
      ),
      title: Text(
        data['title'] ?? "Untitled Chat",
        style: const TextStyle(color: Colors.white),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete, color: Colors.red[400]),
        onPressed: () => onDelete(doc.id),
      ),
      onTap: () => onTap(doc.id),
    );
  }
}