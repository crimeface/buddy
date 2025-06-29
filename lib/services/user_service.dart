import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get user data by ID
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching user data from Firestore: $e');
      return null;
    }
  }

  /// Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final userId = currentUserId;
    if (userId == null) return null;
    return await getUserData(userId);
  }

  /// Update user data
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _database.child('users').child(userId).update(data);
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }

  /// Update current user data
  Future<void> updateCurrentUserData(Map<String, dynamic> data) async {
    final userId = currentUserId;
    if (userId == null) return;
    await updateUserData(userId, data);
  }

  /// Get user's online status
  Stream<bool> getUserOnlineStatus(String userId) {
    return _database
        .child('users')
        .child(userId)
        .child('online')
        .onValue
        .map((event) {
          if (event.snapshot.value == null) return false;
          return event.snapshot.value as bool;
        });
  }

  /// Set current user's online status
  Future<void> setOnlineStatus(bool isOnline) async {
    final userId = currentUserId;
    if (userId == null) return;
    
    try {
      await _database.child('users').child(userId).child('online').set(isOnline);
      
      // Set last seen timestamp when going offline
      if (!isOnline) {
        await _database.child('users').child(userId).child('lastSeen').set(
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      print('Error setting online status: $e');
    }
  }

  /// Get user's last seen timestamp
  Future<DateTime?> getLastSeen(String userId) async {
    try {
      final snapshot = await _database.child('users').child(userId).child('lastSeen').get();
      if (snapshot.value != null) {
        final timestamp = snapshot.value as int;
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      print('Error fetching last seen: $e');
      return null;
    }
  }

  /// Search users by username
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final snapshot = await _database.child('users').get();
      if (snapshot.value == null) return [];
      
      final Map<dynamic, dynamic> usersMap = 
          snapshot.value as Map<dynamic, dynamic>;
      
      final List<Map<String, dynamic>> results = [];
      usersMap.forEach((key, value) {
        if (value is Map) {
          final userData = Map<String, dynamic>.from(value);
          final username = userData['username']?.toString().toLowerCase() ?? '';
          
          if (username.contains(query.toLowerCase())) {
            userData['id'] = key.toString();
            results.add(userData);
          }
        }
      });
      
      return results;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
} 