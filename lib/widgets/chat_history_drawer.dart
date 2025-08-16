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
            _buildSubscriptionInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionInfo(BuildContext context) {
    if (user == null) {
      return Container();
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "No Active Plan",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          );
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final int messagesUsed = data['messagesUsed'] ?? 0;
        final int maxMessages = data['maxMessages'] ?? 0;
        final Timestamp endDateTimestamp = data['endDate'];
        final DateTime endDate = endDateTimestamp.toDate();
        final int remainingDays = endDate.difference(DateTime.now()).inDays + 1;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Active Plan: ${data['plan']}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "Messages: ${messagesUsed} / ${maxMessages}",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                "Days Remaining: ${remainingDays > 0 ? remainingDays : 0}",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        );
      },
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