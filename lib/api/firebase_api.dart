import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/user_utils.dart';

// Global navigator key for handling notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _database = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  // Current chat room tracking
  String? _currentChatRoomId;
  bool _isInChatScreen = false;

  // Notification channels
  static const String _chatChannelId = 'chat_notifications';
  static const String _chatChannelName = 'Chat Messages';
  static const String _chatChannelDescription = 'Notifications for new chat messages';

  static const String _generalChannelId = 'general_notifications';
  static const String _generalChannelName = 'General Notifications';
  static const String _generalChannelDescription = 'General app notifications';

  // Notification IDs
  static const int _chatNotificationId = 1000;
  static const int _generalNotificationId = 2000;

  // Singleton pattern
  static final FirebaseApi _instance = FirebaseApi._internal();
  factory FirebaseApi() => _instance;
  FirebaseApi._internal();

  // Getters for external access
  static FirebaseApi get instance => _instance;

  // Methods to track chat state
  void setCurrentChatRoom(String? chatRoomId) {
    _currentChatRoomId = chatRoomId;
    _isInChatScreen = chatRoomId != null;
  }

  void setChatScreenState(bool isInChat) {
    _isInChatScreen = isInChat;
  }

  Future<void> initNotifications() async {
    // Request permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get FCM token
    final fCMToken = await _firebaseMessaging.getToken();
    print("FCM Token: $fCMToken");

    // Save FCM token to user's profile
    if (fCMToken != null && _auth.currentUser != null) {
      await _saveFCMToken(fCMToken);
    }

    // Create notification channels
    await _createNotificationChannels();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification taps when app is terminated
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);

    // Listen for authentication state changes
    _auth.authStateChanges().listen(_handleAuthStateChange);

    // Set up chat message listeners if user is already authenticated
    if (_auth.currentUser != null) {
      _setupChatMessageListeners();
    }
  }

  Future<void> _createNotificationChannels() async {
    // Chat notifications channel (high priority)
    final androidChatChannel = AndroidNotificationChannel(
      _chatChannelId,
      _chatChannelName,
      description: _chatChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
      showBadge: true,
    );

    // General notifications channel
    final androidGeneralChannel = AndroidNotificationChannel(
      _generalChannelId,
      _generalChannelName,
      description: _generalChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Create channels
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChatChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidGeneralChannel);
  }

  Future<void> _initializeLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _saveFCMToken(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Save to Realtime Database
        await _database.child('users').child(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': DateTime.now().millisecondsSinceEpoch,
        });

        // Save to SharedPreferences for offline access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      } catch (e) {
        print('Error saving FCM token: $e');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }

    // Handle chat messages specifically
    if (message.data['type'] == 'chat_message') {
      _handleChatMessageNotification(message);
    } else {
      _showGeneralNotification(message);
    }
  }

  void _handleChatMessageNotification(RemoteMessage message) {
    final data = message.data;
    final senderId = data['senderId'];
    final senderName = data['senderName'] ?? 'Unknown User';
    final messageContent = data['message'] ?? 'New message';
    final chatRoomId = data['chatRoomId'];

    // Don't show notification if user is in the same chat
    if (_isUserInChat(chatRoomId)) {
      return;
    }

    // Check user notification settings
    _checkAndShowNotification(
      senderId: senderId,
      senderName: senderName,
      message: messageContent,
      chatRoomId: chatRoomId,
    );
  }

  void _showGeneralNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        _generalNotificationId + notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _generalChannelId,
            _generalChannelName,
            channelDescription: _generalChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    
    final data = message.data;
    if (data['type'] == 'chat_message') {
      _navigateToChat(data);
    }
    // Add other navigation logic here
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      if (data['type'] == 'chat_message') {
        _navigateToChat(data);
      }
    }
  }

  void _navigateToChat(Map<String, dynamic> data) {
    final senderId = data['senderId'];
    final senderName = data['senderName'] ?? 'User';
    
    if (senderId != null && navigatorKey.currentState != null) {
      // Navigate to chat screen
      navigatorKey.currentState!.pushNamed(
        '/chat',
        arguments: {
          'otherUserId': senderId,
          'otherUserName': senderName,
        },
      );
    }
  }

  bool _isUserInChat(String? chatRoomId) {
    // Check if user is currently in the chat room
    return _isInChatScreen && _currentChatRoomId == chatRoomId;
  }

  Future<void> _checkAndShowNotification({
    required String? senderId,
    required String senderName,
    required String message,
    required String? chatRoomId,
  }) async {
    try {
      // Get user notification settings
      final settings = await getUserNotificationSettings();
      if (!settings['chatNotifications']) {
        return; // User has disabled chat notifications
      }

      // Show notification
      _localNotifications.show(
        _chatNotificationId + (senderId?.hashCode ?? 0),
        senderName,
        message,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _chatChannelId,
            _chatChannelName,
            channelDescription: _chatChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF3B82F6),
            enableVibration: settings['vibrationEnabled'],
            vibrationPattern: settings['vibrationEnabled'] 
                ? Int64List.fromList([0, 250, 250, 250])
                : null,
            category: AndroidNotificationCategory.message,
            styleInformation: BigTextStyleInformation(message),
            groupKey: 'chat_messages',
            groupAlertBehavior: GroupAlertBehavior.all,
            autoCancel: true,
            ongoing: false,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: settings['soundEnabled'],
            categoryIdentifier: 'chat_message',
          ),
        ),
        payload: json.encode({
          'type': 'chat_message',
          'senderId': senderId,
          'senderName': senderName,
          'chatRoomId': chatRoomId,
          'message': message,
        }),
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  void _setupChatMessageListeners() {
    final user = _auth.currentUser;
    if (user == null) return;

    _database.child('chat_rooms').onValue.listen(
      (event) async {
        if (event.snapshot.value != null) {
          final chatRooms = event.snapshot.value as Map<dynamic, dynamic>;
          for (final entry in chatRooms.entries) {
            final chatRoomId = entry.key;
            final chatRoomData = entry.value;
            if (chatRoomData is Map) {
              final metadata = chatRoomData['metadata'] as Map<dynamic, dynamic>?;
              if (metadata != null) {
                final participants = Map<String, dynamic>.from(metadata['participants'] ?? {});
                if (participants[user.uid] == true) {
                  final lastSenderId = metadata['lastSenderId'] as String?;
                  final lastMessage = metadata['lastMessage'] as String?;
                  final lastMessageTime = metadata['lastMessageTime'] as int?;
                  if (lastSenderId != null && lastSenderId != user.uid) {
                    if (lastMessageTime != null && DateTime.now().millisecondsSinceEpoch - lastMessageTime < 30000) {
                      // Fetch sender's username from Firestore
                      String senderName = 'User';
                      try {
                        final doc = await FirebaseFirestore.instance.collection('users').doc(lastSenderId).get();
                        if (doc.exists) {
                          final data = doc.data();
                          senderName = data?['username'] ?? data?['displayName'] ?? 'User';
                        }
                      } catch (_) {}
                      _checkAndShowNotification(
                        senderId: lastSenderId,
                        senderName: senderName,
                        message: lastMessage ?? 'New message',
                        chatRoomId: chatRoomId.toString(),
                      );
                    }
                  }
                }
              }
            }
          }
        }
      },
      onError: (error) {
        print('Error listening to chat rooms: $error');
      },
    );
  }

  void _handleAuthStateChange(User? user) {
    if (user != null) {
      // User signed in
      print('User signed in: ${user.uid}');
      _setupChatMessageListeners();
      
      // Get and save FCM token for the new user
      _firebaseMessaging.getToken().then((token) {
        if (token != null) {
          _saveFCMToken(token);
        }
      });
    } else {
      // User signed out
      print('User signed out');
      // Clear chat room tracking
      setCurrentChatRoom(null);
      setChatScreenState(false);
      // Clear all notifications
      clearAllNotifications();
    }
  }

  // Public methods for external use
  Future<void> sendChatNotification({
    required String receiverId,
    required String senderName,
    required String message,
    required String chatRoomId,
  }) async {
    try {
      print('Attempting to send chat notification to $receiverId');
      
      // Check if current user is the receiver (don't show notification to sender)
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == receiverId) {
        print('Not showing notification to sender');
        return;
      }
      
      // Show local notification
      await _checkAndShowNotification(
        senderId: receiverId,
        senderName: senderName,
        message: message,
        chatRoomId: chatRoomId,
      );
      
      print('Chat notification sent successfully');
    } catch (e) {
      print('Error in sendChatNotification: $e');
    }
  }

  Future<void> updateUserNotificationSettings({
    required bool chatNotifications,
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _database.child('users').child(user.uid).update({
        'notificationSettings': {
          'chatNotifications': chatNotifications,
          'soundEnabled': soundEnabled,
          'vibrationEnabled': vibrationEnabled,
        },
      });
    }
  }

  Future<Map<String, dynamic>> getUserNotificationSettings() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('user_settings').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        return {
          'chatNotifications': data?['notifications_enabled'] ?? true,
          'soundEnabled': true, // You can extend this if you add more settings
          'vibrationEnabled': true,
        };
      }
    }
    return {
      'chatNotifications': true,
      'soundEnabled': true,
      'vibrationEnabled': true,
    };
  }

  // Method to clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Method to clear specific chat notifications
  Future<void> clearChatNotifications(String senderId) async {
    await _localNotifications.cancel(_chatNotificationId + senderId.hashCode);
  }

  // Method to get notification badge count
  Future<int> getNotificationBadgeCount() async {
    // This would need to be implemented based on your app's requirements
    return 0;
  }

  // Method to update notification badge count
  Future<void> updateNotificationBadgeCount(int count) async {
    // This would need to be implemented based on your app's requirements
  }

  // Method to show test notification
  Future<void> showTestNotification() async {
    try {
      print('Showing test notification...');
      
      await _localNotifications.show(
        9999, // Test notification ID
        'Test Notification',
        'This is a test notification from the chat system',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _chatChannelId,
            _chatChannelName,
            channelDescription: _chatChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF3B82F6),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      
      print('Test notification sent successfully');
    } catch (e) {
      print('Error showing test notification: $e');
      rethrow;
    }
  }
}
