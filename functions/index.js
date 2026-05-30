// ============================================================
// Firebase Cloud Functions - Notification Triggers
// Project: donateconnect-22fa4
// ============================================================
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// ============================================================
// TRIGGER 1: New Message → Notify Recipient
// Fires every time a new message is added to any chat.
// ============================================================
exports.onNewMessage = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
      const message = snap.data();
      const senderId = message.senderId;
      const text = message.text || "";

      // Get the chat document to find the other participant
      const chatDoc = await db.collection("chats")
          .doc(context.params.chatId)
          .get();
      if (!chatDoc.exists) return null;

      const participants = chatDoc.data().participants || [];
      const recipientId = participants.find((id) => id !== senderId);
      if (!recipientId) return null;

      // Get the sender's name for the notification
      const senderDoc = await db.collection("users").doc(senderId).get();
      const senderName = senderDoc.exists ?
          (senderDoc.data().FullName || senderDoc.data().name || "Someone") :
          "Someone";

      // Write the notification document
      await db.collection("notifications").add({
        userId: recipientId,
        type: "message",
        title: `New message from ${senderName}`,
        body: text.length > 80 ? text.substring(0, 80) + "..." : text,
        senderId: senderId,
        isRead: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    });

// ============================================================
// TRIGGER 2: New Donation Posted → Notify Waitlisted Users
// Fires when a new donation is created.
// Checks the requests collection for matching category/item.
// ============================================================
exports.onNewDonation = functions.firestore
    .document("donations/{donationId}")
    .onCreate(async (snap, context) => {
      const donation = snap.data();
      const category = donation.category;
      const title = donation.title || "an item";

      if (!category) return null;

      // Find all approved requests with matching category
      const matchingRequests = await db.collection("requests")
          .where("status", "==", "approved")
          .where("category", "==", category)
          .get();

      if (matchingRequests.empty) return null;

      // Send a notification to each matched requester
      const batch = db.batch();
      matchingRequests.docs.forEach((requestDoc) => {
        const request = requestDoc.data();
        const requesterId = request.requesterId;
        if (!requesterId) return;

        const notifRef = db.collection("notifications").doc();
        batch.set(notifRef, {
          userId: requesterId,
          type: "match",
          title: "🎁 A match was found for you!",
          body: `Someone just donated "${title}" which matches your request for ${category}.`,
          donationId: context.params.donationId,
          isRead: false,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();
      return null;
    });

// ============================================================
// TRIGGER 3: Organization Approved → Notify the Organization
// Fires when verificationStatus changes to 'approved'.
// ============================================================
exports.onOrgApproved = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();

      // Only act if verificationStatus just changed to 'approved'
      if (before.verificationStatus === after.verificationStatus) return null;
      if (after.verificationStatus !== "approved") return null;
      if (after.role !== "organization") return null;

      await db.collection("notifications").add({
        userId: context.params.userId,
        type: "org_approved",
        title: "✅ Your organization is verified!",
        body: "Congratulations! Your organization account has been approved. You can now post causes and reach donors.",
        isRead: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    });

// ============================================================
// TRIGGER 4: Request Approved by Admin → Notify Requester
// Fires when an admin approves a help request.
// ============================================================
exports.onRequestApproved = functions.firestore
    .document("requests/{requestId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();

      if (before.status === after.status) return null;
      if (after.status !== "approved") return null;

      const requesterId = after.requesterId;
      if (!requesterId) return null;

      await db.collection("notifications").add({
        userId: requesterId,
        type: "request_approved",
        title: "✅ Your request was approved!",
        body: `Your request for "${after.title || after.item || "an item"}" has been approved. Donors can now see it.`,
        isRead: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    });
