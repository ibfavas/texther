import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textherapp/screens/subscription_page.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/gpt_service.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/chat_screen_content.dart';
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
  String _subscribeButtonText = '✨ Subscribe';

  late StreamSubscription<QuerySnapshot> _chatHistorySubscription;
  late StreamSubscription<DocumentSnapshot> _subscriptionStatusSubscription;
  List<DocumentSnapshot> _chatHistoryDocs = [];

  @override
  void initState() {
    super.initState();
    _textFocusNode = FocusNode();
    _startNewChat();
    _loadUserAndName();
    _listenToChatHistory();
    _listenToSubscriptionStatus();
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

  void _listenToSubscriptionStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _subscriptionStatusSubscription = _firestore
          .collection('subscriptions')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          if (data['active'] == true && data['endDate'].toDate().isAfter(DateTime.now())) {
            setState(() {
              _subscribeButtonText = data['plan'];
            });
          } else {
            setState(() {
              _subscribeButtonText = '✨ Subscribe';
            });
          }
        } else {
          setState(() {
            _subscribeButtonText = '✨ Subscribe';
          });
        }
      });
    }
  }

  Future<void> _loadUserAndName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {

      if (user.displayName != null && user.displayName!.isNotEmpty) {
        final newName = user.displayName!;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', newName);
        setState(() {
          _userName = newName;
          _isLoadingName = false;
        });
      } else {

        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data()?['name'] != null) {
          final newName = userDoc.data()?['name'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userName', newName);
          setState(() {
            _userName = newName;
            _isLoadingName = false;
          });
        } else {

          if (user.email != null && user.email!.isNotEmpty) {
            final emailName = user.email!.split('@')[0];
            setState(() {
              _userName = emailName;
              _isLoadingName = false;
            });
          } else {
            setState(() {
              _userName = 'User';
              _isLoadingName = false;
            });
          }
        }
      }
    } else {
      setState(() {
        _isLoadingName = false;
        _userName = 'User';
      });
    }
  }

  @override
  void dispose() {
    _textFocusNode.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _chatHistorySubscription.cancel();
    _subscriptionStatusSubscription.cancel();
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
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _toneButton("Friendly", Colors.white),
                    _toneButton("Flirty", Colors.white),
                    _toneButton("Impress", Colors.white),
                    _toneButton("Loving", Colors.white),
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
      child: Text(text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Future<void> _sendWithGpt(String tone) async {
    final userMessage = _textController.text.trim();
    if (userMessage.isEmpty || _currentChatId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final subDoc = await _firestore.collection('subscriptions').doc(user.uid).get();
    if (!subDoc.exists || subDoc.data()?['active'] != true || subDoc.data()?['endDate'].toDate().isBefore(DateTime.now())) {
      _showSubscriptionPrompt();
      return;
    }

    final int messagesUsed = subDoc.data()?['messagesUsed'] ?? 0;
    final int maxMessages = subDoc.data()?['maxMessages'] ?? 0;
    if (messagesUsed >= maxMessages) {
      _showSubscriptionPrompt();
      return;
    }

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

      await _firestore.collection('subscriptions').doc(user.uid).update({
        'messagesUsed': FieldValue.increment(1),
      });

      _scrollToEnd();
    } catch (e) {
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

  void _showSubscriptionPrompt() {
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'You have reached your message limit. Please subscribe to a plan to continue.',
        ),
        action: SnackBarAction(
          label: 'Subscribe',
          onPressed: _openSubscriptionPage,
        ),
      ),
    );
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('userName');

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

  void _openSubscriptionPage() {
    _textFocusNode.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SubscriptionPage()),
    );
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
            onPressed: _openSubscriptionPage,
            child: Text(_subscribeButtonText, style: const TextStyle(color: Colors.white)),
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      drawer: ChatHistoryDrawer(
        user: user,
        chatHistoryDocs: _chatHistoryDocs,
        currentChatId: _currentChatId,
        onChatSelected: _openChat,
        onNewChat: _startNewChat,
        onDeleteChat: _deleteChat,
      ),
      body: _isLoadingName
          ? const Center(child: CircularProgressIndicator())
          : ChatScreenContent(
        user: user,
        userName: _userName ?? 'User',
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
}