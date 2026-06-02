import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/chat.dart';
import '../models/message.dart';

import '../utils/network_config.dart';

class ChatProvider extends ChangeNotifier {
  final String _baseUrl = NetworkConfig.baseUrl;

  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer mock-token',
  };

  // Sidebar state
  bool _isSidebarOpen = false;
  bool get isSidebarOpen => _isSidebarOpen;

  // Active chat
  String? _activeChatId;
  String? get activeChatId => _activeChatId;

  // Typing indicator
  bool _isTyping = false;
  bool get isTyping => _isTyping;

  // Input Controller
  final TextEditingController _inputController = TextEditingController();
  TextEditingController get inputController => _inputController;

  // Chats store
  final List<Chat> _chats = [];
  List<Chat> get chats => _chats;

  ChatProvider() {
    // Fetch initial chat sessions from the backend
    fetchSessions();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Chat? get activeChat {
    if (_activeChatId == null) return null;
    try {
      return _chats.firstWhere((c) => c.id == _activeChatId);
    } catch (_) {
      return null;
    }
  }

  List<Message> get activeMessages => activeChat?.messages ?? [];

  // Grouped chats
  List<Chat> get todayChats => _chats.where((c) {
        final now = DateTime.now();
        return c.createdAt.year == now.year &&
            c.createdAt.month == now.month &&
            c.createdAt.day == now.day;
      }).toList();

  List<Chat> get yesterdayChats => _chats.where((c) {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        return c.createdAt.year == yesterday.year &&
            c.createdAt.month == yesterday.month &&
            c.createdAt.day == yesterday.day;
      }).toList();

  List<Chat> get last7DaysChats => _chats.where((c) {
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        final yesterday = now.subtract(const Duration(days: 1));
        return c.createdAt.isAfter(sevenDaysAgo) &&
            c.createdAt.isBefore(DateTime(
                yesterday.year, yesterday.month, yesterday.day));
      }).toList();

  // Search
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<Chat> get filteredChats {
    if (_searchQuery.isEmpty) return _chats;
    return _chats
        .where(
            (c) => c.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleSidebar() {
    _isSidebarOpen = !_isSidebarOpen;
    notifyListeners();
  }

  void openSidebar() {
    _isSidebarOpen = true;
    notifyListeners();
  }

  void closeSidebar() {
    _isSidebarOpen = false;
    notifyListeners();
  }

  Future<void> fetchSessions() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/sessions'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> sessions = body['data']['sessions'] ?? [];
          _chats.clear();
          
          for (final s in sessions) {
            final chat = Chat(
              id: s['id'] as String,
              title: s['title'] as String,
              createdAt: DateTime.parse(s['createdAt'] as String),
            );
            _chats.add(chat);
          }
          
          if (_chats.isNotEmpty && _activeChatId == null) {
            selectChat(_chats.first.id);
          } else {
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
    }
  }

  Future<void> selectChat(String chatId) async {
    _activeChatId = chatId;
    notifyListeners();

    // Fetch messages for this chat
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/sessions/$chatId/messages'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> msgs = body['data']['messages'] ?? [];
          final chat = activeChat;
          if (chat != null && chat.id == chatId) {
            chat.messages.clear();
            for (final m in msgs) {
              final role = m['role'] as String;
              final text = m['content'] as String;
              final timestamp = DateTime.parse(m['createdAt'] as String);
              
              // Get usedModules if present
              List<String>? modules;
              if (m['metadata'] != null && m['metadata']['usedModules'] != null) {
                modules = List<String>.from(m['metadata']['usedModules']);
              }

              if (role == 'user') {
                chat.messages.add(Message(
                  id: m['id'] as String,
                  type: MessageType.user,
                  text: text,
                  timestamp: timestamp,
                ));
              } else {
                final metadata = m['metadata'] as Map<String, dynamic>?;
                chat.messages.add(Message(
                  id: m['id'] as String,
                  type: MessageType.assistant,
                  text: text,
                  usedModules: modules,
                  metadata: metadata,
                  timestamp: timestamp,
                ));
                
                // Append appropriate display cards if modules are triggered
                if (modules != null) {
                  _appendCardsForModules(chat, modules, metadata);
                }
              }
            }
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  Future<void> createNewChat() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/sessions'),
        headers: _headers,
        body: jsonEncode({'title': 'New Chat'}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final s = body['data']['session'];
          final newChat = Chat(
            id: s['id'] as String,
            title: s['title'] as String,
            createdAt: DateTime.parse(s['createdAt'] as String),
          );
          _chats.insert(0, newChat);
          _activeChatId = newChat.id;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error creating new session: $e');
      
      // Fallback local creation if backend offline
      final newChat = Chat(
        id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Chat',
      );
      _chats.insert(0, newChat);
      _activeChatId = newChat.id;
      notifyListeners();
    }
  }

  void deleteChat(String chatId) {
    // Delete locally and try backend asynchronously
    _chats.removeWhere((c) => c.id == chatId);
    if (_activeChatId == chatId) {
      _activeChatId = _chats.isNotEmpty ? _chats.first.id : null;
    }
    notifyListeners();
    
    // Asynchronous backend delete if possible (not strictly required by user, but nice to have)
    http.delete(
      Uri.parse('$_baseUrl/chat/sessions/$chatId'),
      headers: _headers,
    ).catchError((e) => debugPrint('Error deleting session: $e'));
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // If no active chat, create one on backend
    if (_activeChatId == null) {
      await createNewChat();
    }

    final chat = activeChat!;
    if (chat.title == 'New Chat' && chat.messages.isEmpty) {
      chat.title = text.length > 30 ? '${text.substring(0, 30)}...' : text;
    }

    // Add user message locally first for instant UI response
    final userMsg = Message.user(text);
    chat.messages.add(userMsg);
    notifyListeners();

    // Start AI typing indicator
    _isTyping = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/sessions/${chat.id}/messages'),
        headers: _headers,
        body: jsonEncode({'message': text}),
      );

      _isTyping = false;
      notifyListeners();

          if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final d = body['data'];
          final reply = d['message']['content'] as String;
          final metadata = d['message']['metadata'] as Map<String, dynamic>?;
          
          List<String>? modules;
          if (body['meta'] != null && body['meta']['usedModules'] != null) {
            modules = List<String>.from(body['meta']['usedModules']);
          }

          chat.messages.add(Message.assistant(
            reply,
            usedModules: modules,
            metadata: metadata,
          ));

          // Append appropriate cards for visual modules
          if (modules != null) {
            _appendCardsForModules(chat, modules, metadata);
          }
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Error sending message to backend: $e');
    }

    // Fallback if backend call fails
    _isTyping = false;
    chat.messages.add(Message.assistant(
      'Sorry, I had trouble reaching the AI co-founder brain. Please verify that the backend server is running locally on port 3000.',
      usedModules: ['AI Decision Engine'],
    ));
    notifyListeners();
  }

  void _appendCardsForModules(Chat chat, List<String> modules, Map<String, dynamic>? metadata) {
    final meta = metadata ?? {};
    if (modules.contains('Product Idea Generator')) {
      chat.messages.add(Message.ideaCard(meta));
    }
    if (modules.contains('Product Validation')) {
      chat.messages.add(Message.taskCard(meta));
    }
    if (modules.contains('E-commerce Roadmap') || modules.contains('Business Plan Generator')) {
      chat.messages.add(Message.roadmapCard(meta));
    }
  }

  // Settings state
  bool _darkMode = true;
  bool _notifications = true;
  bool _memoryTracking = true;
  String _aiModel = 'GPT-4';
  String _responseLength = 'Medium';

  bool get darkMode => _darkMode;
  bool get notifications => _notifications;
  bool get memoryTracking => _memoryTracking;
  String get aiModel => _aiModel;
  String get responseLength => _responseLength;

  void toggleDarkMode(bool v) {
    _darkMode = v;
    notifyListeners();
  }

  void toggleNotifications(bool v) {
    _notifications = v;
    notifyListeners();
  }

  void toggleMemoryTracking(bool v) {
    _memoryTracking = v;
    notifyListeners();
  }

  void setAiModel(String v) {
    _aiModel = v;
    notifyListeners();
  }

  void setResponseLength(String v) {
    _responseLength = v;
    notifyListeners();
  }
}
