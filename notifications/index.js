const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// ✅ Helper function - ตรวจสอบว่าควรส่ง push notification หรือไม่
function shouldSend(notificationType) {
  // ❌ ประเภท notification ที่ไม่ควรส่ง push (in-app only)
  const inAppOnlyTypes = [
    "NotificationType.motivational",
    "NotificationType.settingChanged",
  ];

  // ✅ ถ้า notification type เป็น in-app only ให้ return false
  if (notificationType && inAppOnlyTypes.includes(notificationType)) {
    return false;
  }

  // ✅ ประเภทอื่นส่ง push ได้
  return true;
}

exports.sendNotificationOnCreate = onDocumentCreated(
  "users/{userId}/notifications/{notificationId}",
  async (event) => {
    try {
      const snap = event.data;
      if (!snap) return;

      const data = snap.data();
      const userId = event.params.userId;

      console.log("New notification:", data);

      // ✅ ดึง user document
      const userDoc = await admin.firestore()
        .collection("users")
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        console.log("User document not found:", userId);
        return;
      }

      const userData = userDoc.data();

      // ✅ เช็คเปิด/ปิด notification
      const notificationsEnabled =
      userData && userData.notificationsEnabled !== undefined
        ? userData.notificationsEnabled
        : true;

      if (!notificationsEnabled) {
        console.log("⛔ Notifications disabled:", userId);
        return;
      }

      // ✅ ดึง FCM token
      const fcmToken =
        userData && userData.fcmToken
          ? userData.fcmToken
          : null;

      if (!fcmToken) {
        console.log("⚠️ No FCM token:", userId);
        return;
      }

      // ✅ เช็คประเภท notification
      const notificationType = data.type || "";
      const shouldSendNotification = shouldSend(notificationType);

      if (!shouldSendNotification) {
        console.log("📌 Skip in-app only:", notificationType);
        return;
      }

      // ✅ settings
      const soundEnabled =
        userData && userData.soundEnabled !== undefined
          ? userData.soundEnabled
          : true;

      const vibrationEnabled =
        userData && userData.vibrationEnabled !== undefined
          ? userData.vibrationEnabled
          : true;

      // ✅ message
      const message = {
        token: fcmToken,
        notification: {
          title: data.title || "New Notification",
          body: data.message || "",
        },
        android: {
          priority: "high",
          notification: {
            sound: soundEnabled ? "default" : undefined,
            channelId: "default",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: soundEnabled ? "default" : undefined,
              badge: 1,
              mutableContent: true,
            },
          },
        },
        webpush: {
          notification: {
            badge: "https://example.com/badge.png",
            tag: "notification",
            requireInteraction: false,
          },
        },
      };

      // ✅ ส่ง notification
      const messageId = await admin.messaging().send(message);

      console.log("✅ Sent:", messageId);

    } catch (error) {
      console.error("❌ Error:", error.message);
      console.error("Code:", error.code);
      console.error(error);
    }
  }
);