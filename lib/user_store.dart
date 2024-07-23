import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_openai/dart_openai.dart';

class Message {
  final DateTime date;
  final String? model;
  final String content;

  Message({DateTime? date, String? model, required String content})
      : this.date = date ?? DateTime.now(),
        this.model = model,
        this.content = content;

  Message.fromDb(Map<String, Object?> json)
      : this(
            date: json['date'] != null
                ? (json['date']! as Timestamp).toDate()
                : DateTime.now(),
            content: json['content'] != null ? json['content'] as String : "",
            model: json['model'] != null ? json['model'] as String : null);

  Map<String, Object?> toDb() {
    return {
      'date': Timestamp.fromDate(date),
      'model': model,
      'content': content,
    };
  }

  OpenAIChatCompletionChoiceMessageModel toOpenAI() {
    return OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          content,
        ),
      ],
      role: model != null
          ? OpenAIChatMessageRole.user
          : OpenAIChatMessageRole.assistant,
    );
  }

  bool user() {
    return model?.isNotEmpty ?? false;
  }

  String docKey() {
    return date.toIso8601String();
  }
}

class Chat {
  final DateTime date;
  final String model;

  Chat({DateTime? date, String? model})
      : this.date = date ?? DateTime.now(),
        this.model = model ?? "gpt-4o";

  Chat.fromDb(Map<String, Object?> json)
      : this(
            date: (json['date']! as Timestamp).toDate(),
            model: json['model']! as String);

  Map<String, Object?> toDb() {
    return {
      'date': Timestamp.fromDate(date),
      'model': model,
    };
  }

  String docKey() {
    return date.toIso8601String();
  }
}

class UserStore {
  final String uid;
  final CollectionReference<Chat> chatsRef;

  static UserStore? _instance;

  UserStore._(this.uid, this.chatsRef);

  factory UserStore(String uid) {
    final chatsRef = FirebaseFirestore.instance
        .collection('users/${uid}/chats')
        .withConverter<Chat>(
          fromFirestore: (snapshot, _) {
            return Chat.fromDb(snapshot.data()!);
          },
          toFirestore: (entry, _) => entry.toDb(),
        );
    _instance ??= UserStore._(uid, chatsRef);
    return _instance!;
  }

  static void clear() {
    _instance = null;
  }

  static UserStore get instance {
    assert(_instance != null, 'UserStore must be initialized before accessing');
    return _instance!;
  }

  Query<Chat> readChats() {
    return chatsRef.orderBy('date', descending: true);
  }

  Future<void> deleteChat(String chatKey) async {
    await chatsRef.doc(chatKey).delete();
  }

  Future<void> saveChat(Chat chat) async {
    await chatsRef.doc(chat.docKey()).set(chat);
  }

  Query<Message> readChatMessages(Chat chat) {
    return chatsRef
        .doc(chat.docKey())
        .collection('messages')
        .withConverter<Message>(
          fromFirestore: (snapshot, _) {
            return Message.fromDb(snapshot.data()!);
          },
          toFirestore: (message, _) => message.toDb(),
        )
        .orderBy('date', descending: false);
  }

  Future<void> addMessage(Chat chat, Message message) async {
    await chatsRef
        .doc(chat.docKey())
        .collection('messages')
        .withConverter<Message>(
          fromFirestore: (snapshot, _) => Message.fromDb(snapshot.data()!),
          toFirestore: (message, _) => message.toDb(),
        )
        .doc(message.docKey())
        .set(message);
  }
}
