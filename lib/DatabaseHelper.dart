import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseDatabaseHelper {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // DATABASE STRUCTURE

  // 1. USERS NODE (Conceptual 'users' table)
  // Path: /users/{user_id}
  final DatabaseReference usersRef =
  FirebaseDatabase.instance.ref('users');

  // 2. MESSAGES NODE (Conceptual 'messages' table)
  // Path: /messages/{chat_id}/{message_id}
  // We use the chat ID as the key to group messages efficiently.
  final DatabaseReference messagesRef =
  FirebaseDatabase.instance.ref('messages');

  // 3. NETWORK INFO NODE (Conceptual 'network_info' table)
  final DatabaseReference networkInfoRef =
  FirebaseDatabase.instance.ref('network_info');

  // 4. CHAT METADATA NODE (Required for chat apps)
  final DatabaseReference chatsRef =
  FirebaseDatabase.instance.ref('chats');

  // EXAMPLE: Using the structure references

  /// Sets up a listener to stream all users (contacts)
  Stream<List<Map<String, dynamic>>> streamAllUsers() {
    return usersRef.onValue.map((event) {
      // Logic to convert the snapshot to a list of user objects
      // ...
      return [];
    });
  }

  /// Writes a new user's network info to the database.
  Future<void> saveUserNetworkInfo(String userId, String ssid, String ip) async {
    // We use .child(userId) to create the unique record for that user
    await networkInfoRef.child(userId).set({
      'ssid': ssid,
      'ip': ip,
      'confirmedAt': ServerValue.timestamp, // Use server timestamp
    });
  }
}
