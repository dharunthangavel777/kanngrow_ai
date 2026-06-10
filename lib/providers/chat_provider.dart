import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/chat.dart';
import '../models/message.dart';

import '../utils/network_config.dart';

class ChatProvider extends ChangeNotifier {
  final String _baseUrl = NetworkConfig.baseUrl;

  // Headers are fetched dynamically before each request

  // Sidebar state
  bool _isSidebarOpen = false;
  bool get isSidebarOpen => _isSidebarOpen;

  // Active chat
  String? _activeChatId;
  String? get activeChatId => _activeChatId;

  // Typing indicator
  bool _isTyping = false;
  bool get isTyping => _isTyping;

  // Guard against duplicate message sends
  bool _isSendingMessage = false;
  bool get isSendingMessage => _isSendingMessage;

  // Loading state for initial fetch
  bool _isLoadingSessions = false;
  bool get isLoadingSessions => _isLoadingSessions;

  // Input Controller
  final TextEditingController _inputController = TextEditingController();
  TextEditingController get inputController => _inputController;

  // Chats store
  final List<Chat> _chats = [];
  List<Chat> get chats => _chats;

  ChatProvider() {
    // We intentionally DO NOT fetchSessions() here anymore.
    // It is called by ChatScreen on mount to avoid unauthenticated network calls.
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
    _isLoadingSessions = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/sessions?includeRecent=true'),
        headers: await NetworkConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> sessions = body['data']['sessions'] ?? [];
          final List<dynamic>? recentMessages = body['data']['recentMessages'];
          
          _chats.clear();
          
          for (final s in sessions) {
            final chat = Chat(
              id: s['id'] as String,
              title: s['title'] as String,
              createdAt: DateTime.parse(s['createdAt'] as String),
              isIdea: s['isIdea'] == true,
            );
            _chats.add(chat);
          }
          
          if (_chats.isNotEmpty) {
            _activeChatId = _chats.first.id;
            
            // Parse recent messages if backend provided them
            if (recentMessages != null) {
              final chat = _chats.first;
              chat.messagesLoaded = true;
              if (chat.messages.isEmpty) {
              for (final m in recentMessages) {
                final role = m['role'] as String;
                final text = m['content'] as String;
                final timestamp = DateTime.parse(m['createdAt'] as String);
                
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
                  
                  if (modules != null) {
                    _appendCardsForModules(chat, modules, metadata);
                  }
                }
              }
            }
          } else if (_activeChatId == null) {
             // Fallback if recentMessages is missing
             await selectChat(_chats.first.id);
          }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
    } finally {
      _isLoadingSessions = false;
      notifyListeners();
    }
  }

  Future<void> selectChat(String chatId) async {
    _activeChatId = chatId;
    notifyListeners();

    // Fetch messages for this chat
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/sessions/$chatId/messages'),
        headers: await NetworkConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> msgs = body['data']['messages'] ?? [];
          final chat = activeChat;
          if (chat != null && chat.id == chatId) {
            chat.messagesLoaded = true;
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

  Future<void> createNewChat({bool isIdea = false, String? title}) async {
    // Check if there is already an empty chat with matching isIdea type
    Chat? emptyChat;
    try {
      emptyChat = _chats.firstWhere((c) => c.messagesLoaded && c.messages.isEmpty && c.isIdea == isIdea);
    } catch (_) {}

    if (emptyChat != null) {
      _activeChatId = emptyChat.id;
      if (title != null) {
        emptyChat.title = title;
      }
      notifyListeners();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/sessions'),
        headers: await NetworkConfig.getHeaders(),
        body: jsonEncode({
          'title': title ?? (isIdea ? 'New Business Idea' : 'New Chat'),
          'isIdea': isIdea,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final s = body['data']['session'];
          final newChat = Chat(
            id: s['id'] as String,
            title: s['title'] as String,
            createdAt: DateTime.parse(s['createdAt'] as String),
            isIdea: s['isIdea'] == true,
            messagesLoaded: true,
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
        title: title ?? (isIdea ? 'New Business Idea' : 'New Chat'),
        isIdea: isIdea,
        messagesLoaded: true,
      );
      _chats.insert(0, newChat);
      _activeChatId = newChat.id;
      notifyListeners();
    }
  }

  Future<void> deleteChat(String chatId) async {
    // Delete locally and try backend asynchronously
    _chats.removeWhere((c) => c.id == chatId);
    if (_activeChatId == chatId) {
      _activeChatId = _chats.isNotEmpty ? _chats.first.id : null;
    }
    notifyListeners();
    
    // Asynchronous backend delete if possible (not strictly required by user, but nice to have)
    try {
      await http.delete(
        Uri.parse('$_baseUrl/chat/sessions/$chatId'),
        headers: await NetworkConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Error deleting session: $e');
    }
  }

  List<String> _splitIntoWords(String text) {
    final List<String> tokens = [];
    final RegExp regExp = RegExp(r'(\s+)');
    int lastMatchEnd = 0;

    for (final Match match in regExp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        tokens.add(text.substring(lastMatchEnd, match.start));
      }
      tokens.add(match.group(0)!);
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      tokens.add(text.substring(lastMatchEnd));
    }

    return tokens;
  }

  Future<void> sendMessage(String text, {bool isIdeaPrompt = false}) async {
    if (text.trim().isEmpty) return;
    if (_isSendingMessage) return; // Guard against duplicate sends
    _isSendingMessage = true;
    notifyListeners();

    // If no active chat, create one on backend
    if (_activeChatId == null) {
      await createNewChat();
    }

    final chat = activeChat!;
    if (chat.title == 'New Chat' && chat.messages.isEmpty) {
      chat.title = text.length > 30 ? '${text.substring(0, 30)}...' : text;
    }

    // Add user message locally first for instant UI response
    final userMsg = Message.user(text, isIdeaPrompt: isIdeaPrompt);
    chat.messages.add(userMsg);
    notifyListeners();

    // Start AI typing indicator
    _isTyping = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/sessions/${chat.id}/messages'),
        headers: await NetworkConfig.getHeaders(),
        body: jsonEncode({
          'message': text,
          'model': _aiModel,
        }),
      ).timeout(const Duration(seconds: 25));

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

          // Create an empty assistant message and stream progressively
          final assistantMsg = Message.assistant(
            "",
            usedModules: modules,
            metadata: metadata,
          );
          chat.messages.add(assistantMsg);
          notifyListeners();

          final tokens = _splitIntoWords(reply);
          int tokenCount = 0;
          for (final token in tokens) {
            assistantMsg.text = (assistantMsg.text ?? "") + token;
            tokenCount++;
            if (tokenCount % 15 == 0 || tokenCount == tokens.length) {
              notifyListeners();
              await Future.delayed(const Duration(milliseconds: 4));
            }
          }

          // Append appropriate cards for visual modules
          if (modules != null) {
            _appendCardsForModules(chat, modules, metadata);
          }
          notifyListeners();
          _isSendingMessage = false;
          return;
        }
      }
    } catch (e) {
      debugPrint('Error sending message to backend: $e');
    }

    _isSendingMessage = false;

    // Fallback if backend call fails
    _isTyping = false;
    final fallbackMsg = Message.assistant(
      "",
      usedModules: ['AI Decision Engine'],
    );
    chat.messages.add(fallbackMsg);
    notifyListeners();

    const fallbackText = 'Sorry, I had trouble reaching the AI co-founder brain. Please verify that the backend server is running locally on port 3000.';
    final tokens = _splitIntoWords(fallbackText);
    int tokenCount = 0;
    for (final token in tokens) {
      fallbackMsg.text = (fallbackMsg.text ?? "") + token;
      tokenCount++;
      if (tokenCount % 15 == 0 || tokenCount == tokens.length) {
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 4));
      }
    }
  }

  void _appendCardsForModules(Chat chat, List<String> modules, Map<String, dynamic>? metadata) {
    // Disabled in V2 Ultra Response System to enforce a single flowing markdown response.
  }

  // Settings state
  bool _darkMode = true;
  bool _notifications = true;
  bool _memoryTracking = true;
  String _aiModel = 'Fast (GPT-4o-mini)';
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
