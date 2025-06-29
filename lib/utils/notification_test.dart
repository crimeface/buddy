import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../api/firebase_api.dart';

class NotificationTest {
  static final FirebaseApi _firebaseApi = FirebaseApi.instance;

  /// Test local notification display
  static Future<void> testLocalNotification(BuildContext context) async {
    try {
      await _firebaseApi.showTestNotification();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending test notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Test server-side notification
  static Future<void> testServerNotification(BuildContext context) async {
    try {
      // Get current user ID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to test notifications'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // For now, just show a message that server notifications need to be deployed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Server notifications require Cloud Functions deployment'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing server notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Test notification settings
  static Future<void> testNotificationSettings(BuildContext context) async {
    try {
      final settings = await _firebaseApi.getUserNotificationSettings();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notification Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chat Notifications: ${settings['chatNotifications']}'),
              Text('Sound Enabled: ${settings['soundEnabled']}'),
              Text('Vibration Enabled: ${settings['vibrationEnabled']}'),
              Text('Notifications Initialized: ${_firebaseApi.notificationsInitialized}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting notification settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications(BuildContext context) async {
    try {
      await _firebaseApi.clearAllNotifications();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications cleared!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Test chat notification specifically
  static Future<void> testChatNotification(BuildContext context) async {
    try {
      await _firebaseApi.sendChatNotification(
        receiverId: 'test_receiver',
        senderName: 'Test User',
        message: 'This is a test chat message',
        chatRoomId: 'test_chat_room',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat notification test sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending chat notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show notification test dialog
  static void showTestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Test'),
        content: const Text('Choose a test to run:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              testLocalNotification(context);
            },
            child: const Text('Test Local Notification'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              testServerNotification(context);
            },
            child: const Text('Test Server Notification'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              testChatNotification(context);
            },
            child: const Text('Test Chat Notification'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              testNotificationSettings(context);
            },
            child: const Text('Check Settings'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              clearAllNotifications(context);
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
} 