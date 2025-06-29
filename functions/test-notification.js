const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Test function to manually send a notification
exports.testNotification = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  try {
    const { receiverId, message } = data;
    
    if (!receiverId || !message) {
      throw new functions.https.HttpsError('invalid-argument', 'receiverId and message are required');
    }

    // Get the receiver's FCM token
    const receiverDoc = await admin.firestore().collection('users').doc(receiverId).get();
    
    if (!receiverDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Receiver not found');
    }

    const receiverData = receiverDoc.data();
    const fcmToken = receiverData.fcmToken;

    if (!fcmToken) {
      throw new functions.https.HttpsError('failed-precondition', 'Receiver has no FCM token');
    }

    // Send test notification
    const notificationMessage = {
      token: fcmToken,
      notification: {
        title: 'Test Notification',
        body: message,
      },
      data: {
        type: 'test',
        message: message,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        notification: {
          channelId: 'chat_notifications',
          priority: 'high',
        },
      },
    };

    const response = await admin.messaging().send(notificationMessage);
    
    return {
      success: true,
      messageId: response,
      message: 'Test notification sent successfully'
    };
  } catch (error) {
    console.error('Error sending test notification:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
}); 