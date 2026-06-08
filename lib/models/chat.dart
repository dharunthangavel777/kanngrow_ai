import 'message.dart';

class Chat {
  final String id;
  String title;
  final List<Message> messages;
  final DateTime createdAt;
  final bool isIdea;

  Chat({
    required this.id,
    required this.title,
    List<Message>? messages,
    DateTime? createdAt,
    this.isIdea = false,
  })  : messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now();
}
