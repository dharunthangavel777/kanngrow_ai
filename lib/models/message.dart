import 'package:flutter/foundation.dart';

enum MessageType { user, assistant, ideaCard, taskCard, roadmapCard, validationCard }

class Message {
  final String id;
  final MessageType type;
  String? text;
  final List<String>? usedModules;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final bool isIdeaPrompt; // marks the automated onboarding idea prompt

  Message({
    required this.id,
    required this.type,
    this.text,
    this.usedModules,
    this.metadata,
    this.isIdeaPrompt = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  static Message user(String text, {bool isIdeaPrompt = false}) => Message(
        id: UniqueKey().toString(),
        type: MessageType.user,
        text: text,
        isIdeaPrompt: isIdeaPrompt,
      );

  static Message assistant(String text, {List<String>? usedModules, Map<String, dynamic>? metadata}) => Message(
        id: UniqueKey().toString(),
        type: MessageType.assistant,
        text: text,
        usedModules: usedModules,
        metadata: metadata,
      );

  static Message ideaCard(Map<String, dynamic> metadata) => Message(
        id: UniqueKey().toString(),
        type: MessageType.ideaCard,
        metadata: metadata,
      );

  static Message taskCard(Map<String, dynamic> metadata) => Message(
        id: UniqueKey().toString(),
        type: MessageType.taskCard,
        metadata: metadata,
      );

  static Message roadmapCard(Map<String, dynamic> metadata) => Message(
        id: UniqueKey().toString(),
        type: MessageType.roadmapCard,
        metadata: metadata,
      );

  static Message validationCard(Map<String, dynamic> metadata) => Message(
        id: UniqueKey().toString(),
        type: MessageType.validationCard,
        metadata: metadata,
      );
}
