import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nimbus/files.dart';
import 'package:nimbus/functions.dart';

class FnCall {
  final Map<String, Object?> fnArgs;
  final String fnName;
  Map<String, Object?> fnOutput;

  FnCall({required this.fnArgs, required this.fnName, required this.fnOutput});

  FnCall.fromDb(Map<String, Object?> json)
      : fnArgs = json['fnArgs'] as Map<String, Object?>,
        fnName = json['fnName'] as String,
        fnOutput = json['fnOutput'] is Map<String, Object?>
            ? json['fnOutput'] as Map<String, Object?>
            : {};

  Map<String, Object?> toDb() {
    return {
      'fnArgs': fnArgs,
      'fnName': fnName,
      'fnOutput': fnOutput,
    };
  }

  run() async {
    try {
      fnOutput = await functions[fnName]!(fnArgs);
    } catch (e) {
      fnOutput = {'error': e};
    }
  }
}

class Message {
  final DateTime date;
  final String? model;
  String content;
  final List<String>? filePaths;
  final List<FnCall> fnCalls;

  Message(
      {DateTime? date,
      String? model,
      List<FnCall>? fnCalls,
      List<String>? filePaths,
      required String content})
      : this.date = date ?? DateTime.now(),
        this.filePaths = filePaths ?? [],
        this.model = model,
        this.fnCalls = fnCalls ?? [],
        this.content = content;

  Message.fromDb(Map<String, Object?> json)
      : this(
            date: json['date'] != null
                ? (json['date']! as Timestamp).toDate()
                : DateTime.now(),
            content: json['content'] != null ? json['content'] as String : "",
            fnCalls: json['fnCalls'] != null
                ? (json['fnCalls'] as List<dynamic>)
                    .map((e) => FnCall.fromDb(e as Map<String, Object?>))
                    .toList()
                : [],
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
      'fnCalls': fnCalls.map((e) => e.toDb()).toList(),
    };
  }

  bool isUser() {
    return model?.isEmpty ?? true;
  }

  bool fnCallsDone() {
    final res = fnCalls.map((fn) =>
        fn.fnOutput.containsKey('output') || fn.fnOutput.containsKey('error'));
    return res.every((done) => done);
  }

  // Message getFnCallResMessage() {
  //   final res = fnCalls.map((fn) => fn.fnOutput['output'] ?? '').join('\n');
  //   return Message(
  //       content: res.replaceAll('\n', '').isEmpty
  //           ? 'The script ran successfully.'
  //           : res);
  // }

  Future<Content> toGemini() async {
    final role = model == null ? 'user' : 'model';
    // print('filepaths $filePaths');
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

  bool user() {
    return model?.isNotEmpty ?? false;
  }

  String docKey() {
    return date.toIso8601String();
  }
}

class Chat {
  final DateTime date;

  Chat({DateTime? date}) : this.date = date ?? DateTime.now();

  Chat.fromDb(Map<String, Object?> json)
      : this(date: (json['date']! as Timestamp).toDate());

  Map<String, Object?> toDb() {
    return {
      'date': Timestamp.fromDate(date),
    };
  }

  String docKey() {
    return date.toIso8601String();
  }
}

class UserStore {
  final String uid;
  final CollectionReference<Chat> chatsRef;
  String model;

  static UserStore? _instance;

  UserStore._(this.uid, this.chatsRef, this.model);

  factory UserStore(String uid) {
    final chatsRef = FirebaseFirestore.instance
        .collection('users/${uid}/chats')
        .withConverter<Chat>(
          fromFirestore: (snapshot, _) {
            return Chat.fromDb(snapshot.data()!);
          },
          toFirestore: (entry, _) => entry.toDb(),
        );
    _instance ??= UserStore._(uid, chatsRef, 'gemini-1.5-flash');
    return _instance!;
  }

  static void clear() {
    _instance = null;
  }

  static UserStore get instance {
    assert(_instance != null, 'UserStore must be initialized before accessing');
    return _instance!;
  }

  void setModel(String newModel) {
    model = newModel;
  }

  static getModelOptions() {
    return ['gemini-1.5-flash', 'gemini-1.5-pro'];
  }

  Query<Chat> readChats() {
    return chatsRef.orderBy('date', descending: true);
  }

  Future<void> deleteChat(Chat chat) async {
    final chatDoc = chatsRef.doc(chat.docKey());
    final messagesCollection = chatDoc.collection('messages');

    // Get all messages in the nested collection
    final messagesSnapshot = await messagesCollection.get();

    // Create a batch
    final batch = FirebaseFirestore.instance.batch();

    // Add delete operations for each message document to the batch
    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Add delete operation for the chat document to the batch
    batch.delete(chatDoc);

    // Commit the batch
    await batch.commit();
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

  Future<void> saveMessage(Chat chat, Message message) async {
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
