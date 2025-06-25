import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Send a message
  Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    if (currentUserId == null) return;

    final message = ChatMessage(
      id: '',
      senderId: currentUserId!,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
    );

    // Create a chat room ID (sorted to ensure consistency)
    final List<String> ids = [currentUserId!, receiverId];
    ids.sort();
    final String chatRoomId = ids.join('_');

    // Add message to chat room
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(message.toMap());

    // Update chat room metadata
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'participants': [currentUserId, receiverId],
      'lastMessage': content,
      'lastMessageTime': Timestamp.now(),
      'lastSenderId': currentUserId,
    }, SetOptions(merge: true));
  }

  // Get messages stream for a specific chat
  Stream<List<ChatMessage>> getMessages(String otherUserId) {
    if (currentUserId == null) return Stream.value([]);

    final List<String> ids = [currentUserId!, otherUserId];
    ids.sort();
    final String chatRoomId = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  // Get all chat rooms for current user
  Stream<QuerySnapshot> getChatRooms() {
    if (currentUserId == null) return Stream.value(null as QuerySnapshot);

    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId) async {
    if (currentUserId == null) return;

    final messagesQuery = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in messagesQuery.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
} 