import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nimbus/files.dart';

class Message {
  final DateTime date;
  final String? model;
  final String content;
  final List<String>? filePaths;

  Message(
      {DateTime? date,
      String? model,
      List<String>? filePaths,
      required String content})
      : this.date = date ?? DateTime.now(),
        this.filePaths = filePaths ?? [],
        this.model = model,
        this.content = content;

  Message.fromDb(Map<String, Object?> json)
      : this(
            date: json['date'] != null
                ? (json['date']! as Timestamp).toDate()
                : DateTime.now(),
            content: json['content'] != null ? json['content'] as String : "",
            filePaths: json['filePaths'] != null
                ? (json['filePaths'] as List<dynamic>)
                    .map((e) => e as String)
                    .toList()
                : [],
            model: json['model'] != null ? json['model'] as String : null);

  Map<String, Object?> toDb() {
    return {
      'date': Timestamp.fromDate(date),
      'model': model,
      'content': content,
      'filePaths': filePaths,
    };
  }

  Future<Content> toGemini() async {
    final role = model == null ? 'user' : 'model';
    print('filepaths $filePaths');
    if (filePaths != null && filePaths!.length > 0) {
      List<Part> fileParts = [];
      String cleanContent = content;
      for (var fp in filePaths!) {
        final part = await Files.getPart(fp);
        if (part != null) fileParts.add(part);
        // print(fp);
        cleanContent = cleanContent.replaceAll('@$fp', '');
        // print(cleanContent);
        // print(part.toJson());
      }
      return Content(role, [...fileParts, TextPart(cleanContent)]);
    }
    return Content(role, [TextPart(content)]);
  }

  OpenAIChatCompletionChoiceMessageModel toOpenAI() {
    return OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          content,
        ),
      ],
      role: model == null
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
