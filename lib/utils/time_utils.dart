import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

class TimeUtils {
  static String formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) {
      return 'Just now';
    }

    DateTime dateTime;
    
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Unknown';
    }

    return timeago.format(dateTime);
  }
}
