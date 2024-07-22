import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final DateTime date;
  final String? model;

  Message({DateTime? date, String? model})
      : this.date = date ?? DateTime.now(),
        this.model = model;

  Message.fromDb(Map<String, Object?> json)
      : this(
            date: (json['date']! as Timestamp).toDate(),
            model: json.containsKey('model') ? json['model']! as String : null);

  Map<String, Object?> toDb() {
    return {
      'date': Timestamp.fromDate(date),
      'model': model,
    };
  }

  bool user() {
    return model?.isNotEmpty ?? false;
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

  Future<void> saveChat(String chatKey, Chat chat) async {
    await chatsRef.doc(chatKey).set(chat);
  }

  Query<Message> readChat(String chatKey) {
    return chatsRef
        .doc(chatKey)
        .collection('messages')
        .withConverter<Message>(
          fromFirestore: (snapshot, _) {
            return Message.fromDb(snapshot.data()!);
          },
          toFirestore: (message, _) => message.toDb(),
        )
        .orderBy('date', descending: true);
  }

  Future<void> addMessage(
      String chatKey, String messageKey, Message message) async {
    await chatsRef
        .doc(chatKey)
        .collection('messages')
        .withConverter<Message>(
          fromFirestore: (snapshot, _) {
            return Message.fromDb(snapshot.data()!);
          },
          toFirestore: (message, _) => message.toDb(),
        )
        .add(message);
    ;
  }
}
