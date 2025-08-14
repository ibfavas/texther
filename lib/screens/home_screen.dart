import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Import the dart:async library for StreamSubscription

import '../services/auth_service.dart';
import '../services/gpt_service.dart';
import 'auth/auth_choice_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _textController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final GptService _gptService = GptService();

  String _selectedMode = 'Reply';
  String? _currentChatId;
  late final FocusNode _textFocusNode;

  String? _userName;
  bool _isLoadingName = true;

  // New members for chat history
  late StreamSubscription<QuerySnapshot> _chatHistorySubscription;
  List<DocumentSnapshot> _chatHistoryDocs = [];

  @override
  void initState() {
    super.initState();
    _textFocusNode = FocusNode();
    _startNewChat();
    _loadUserAndName();
    _listenToChatHistory();
  }

  void _listenToChatHistory() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _chatHistorySubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          _chatHistoryDocs = snapshot.docs;
        });
      });
    }
  }

  Future<void> _loadUserAndName() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedName = prefs.getString('userName');

    if (cachedName != null) {
      setState(() {
        _userName = cachedName;
        _isLoadingName = false;
      });
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestore.collection('users').doc(user.uid).snapshots().listen((snapshot) async {
        if (snapshot.exists) {
          final newName = snapshot.data()?['name'];
          if (newName != _userName) {
            await prefs.setString('userName', newName);
            setState(() {
              _userName = newName;
            });
          }
        }
        if (_isLoadingName) {
          setState(() {
            _isLoadingName = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _textFocusNode.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _chatHistorySubscription.cancel(); // Cancel the subscription
    super.dispose();
  }

  void _startNewChat() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestore.collection('users').doc(user.uid).collection('chats').add({
        'createdAt': FieldValue.serverTimestamp(),
        'title': null,
        'lastMode': null,
      }).then((docRef) {
        setState(() {
          _currentChatId = docRef.id;
        });
      });
    }
  }

  void _openChat(String chatId) {
    setState(() {
      _currentChatId = chatId;
    });
    Navigator.of(context).pop();
  }

  Future<void> _deleteChat(String chatId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .doc(chatId)
          .delete();
    }
  }

  Future<String?> _showToneSelectionDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "SELECT A TONE:",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _toneButton("Friendly", Colors.white),
                    _toneButton("Flirt", Colors.white),
                    _toneButton("Impress", Colors.white),
                    _toneButton("Love", Colors.white),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _toneButton(String text, Color color) {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context, text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(text, style: const TextStyle(color: Colors.black,fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Future<void> _sendWithGpt(String tone) async {
    final userMessage = _textController.text.trim();
    if (userMessage.isEmpty || _currentChatId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final chatRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .doc(_currentChatId);

    await chatRef.collection('messages').add({
      'text': userMessage,
      'mode': _selectedMode,
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': user.uid,
    });

    _textController.clear();
    _scrollToEnd();

    final tempMessageRef = await chatRef.collection('messages').add({
      'text': '...',
      'isGenerating': true,
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': 'gpt',
    });

    final chatDoc = await chatRef.get();
    if (!chatDoc.exists || chatDoc.data()?['title'] == null) {
      await chatRef.update({'title': userMessage, 'lastMode': _selectedMode});
    } else {
      await chatRef.update({'lastMode': _selectedMode});
    }

    try {
      final generatedText = await _gptService.generateMessage(
        mode: _selectedMode,
        tone: tone,
        userMessage: userMessage,
      );

      await tempMessageRef.update({
        'text': generatedText,
        'isGenerating': false,
      });

      _scrollToEnd();
    } catch (e) {
      // If there's an error, update the message to show an error state
      await tempMessageRef.update({
        'text': 'Error: Failed to generate response.',
        'isGenerating': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _scrollToEnd() {
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

  Future<void> _confirmSignOut(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to sign out?',
              style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => AuthChoiceScreen()),
                (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error signing out')),
          );
        }
      }
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty || _currentChatId == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final chatRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .doc(_currentChatId);

    await chatRef.collection('messages').add({
      'text': text,
      'mode': _selectedMode,
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': user.uid,
    });

    final chatDoc = await chatRef.get();
    if (!chatDoc.exists || chatDoc.data()?['title'] == null) {
      await chatRef.update({'title': text, 'lastMode': _selectedMode});
    } else {
      await chatRef.update({'lastMode': _selectedMode});
    }

    _textController.clear();
    _scrollToEnd();
  }

  void _updateUserName(String newName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({'name': newName}, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', newName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User name updated to $newName')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _textFocusNode.unfocus();
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Center(
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey[850],
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {},
            child: const Text('✨ Subscribe', style: TextStyle(color: Colors.white)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      drawer: _ChatHistoryDrawer(
        user: user,
        chatHistoryDocs: _chatHistoryDocs,
        currentChatId: _currentChatId,
        onChatSelected: _openChat,
        onNewChat: _startNewChat,
        onDeleteChat: _deleteChat,
      ),
      body: _isLoadingName
          ? const Center(child: CircularProgressIndicator())
          : _userName == null || _userName!.isEmpty
          ? _buildNameEntryScreen(context)
          : _ChatScreenContent(
        user: user,
        userName: _userName!,
        currentChatId: _currentChatId,
        scrollController: _scrollController,
        textController: _textController,
        selectedMode: _selectedMode,
        onModeChanged: (mode) => setState(() => _selectedMode = mode),
        onSendWithGpt: _sendWithGpt,
        onShowToneSelection: _showToneSelectionDialog,
        onSendMessage: _sendMessage,
        textFocusNode: _textFocusNode,
      ),
    );
  }

  Widget _buildNameEntryScreen(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Please enter your name to start using the app.",
              style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Your Name",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (_textController.text.isNotEmpty) {
                  _updateUserName(_textController.text);
                  _textController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Save Name',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHistoryDrawer extends StatelessWidget {
  final User? user;
  final List<DocumentSnapshot> chatHistoryDocs;
  final String? currentChatId;
  final Function(String) onChatSelected;
  final VoidCallback onNewChat;
  final Function(String) onDeleteChat;

  const _ChatHistoryDrawer({
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
                    onDelete: onDeleteChat,
                  )),
                  if (fixItChats.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text("🛠 Fix It Chats", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    ),
                  ...fixItChats.map((doc) => _ChatTile(
                    doc: doc,
                    onTap: onChatSelected,
                    onDelete: onDeleteChat,
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

class _ChatScreenContent extends StatelessWidget {
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

  const _ChatScreenContent({
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
        bottom: 8.0, // This padding will be handled by the keyboard resize
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
        ? const _AnimatedTypingIndicator()
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

class _AnimatedTypingIndicator extends StatefulWidget {
  const _AnimatedTypingIndicator();

  @override
  _AnimatedTypingIndicatorState createState() => _AnimatedTypingIndicatorState();
}

class _AnimatedTypingIndicatorState extends State<_AnimatedTypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final animation = Tween<double>(begin: 1, end: 1.5).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval((index) * 0.2, (index * 0.2) + 0.5, curve: Curves.easeOut),
              ),
            );
            return ScaleTransition(
              scale: animation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}