import 'message.dart';

class Chat {
  final String id;
  String title;
  final List<Message> messages;
  final DateTime createdAt;

  Chat({
    required this.id,
    required this.title,
    List<Message>? messages,
    DateTime? createdAt,
  })  : messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now();
}
