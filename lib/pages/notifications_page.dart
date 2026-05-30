import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAEEDA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF854F0B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF412402)),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'read') _markAllAsRead();
              if (value == 'clear') _clearAll();
            },
            icon: const Icon(Icons.more_vert, color: Color(0xFF854F0B)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'read', child: Text('Mark all read')),
              const PopupMenuItem(value: 'clear', child: Text('Clear all', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFEF9F27),
          labelColor: const Color(0xFFEF9F27),
          unselectedLabelColor: const Color(0xFF888780),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(false), // All
          _buildNotificationList(true),  // Unread only
        ],
      ),
    );
  }

  Widget _buildNotificationList(bool unreadOnly) {
    Query query = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: _userId)
        .orderBy('timestamp', descending: true);

    if (unreadOnly) {
      query = query.where('isRead', isEqualTo: false);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFEF9F27)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final docs = snapshot.data!.docs;
        
        // Grouping logic
        List<dynamic> items = [];
        String lastHeader = "";

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          String header = _getDateHeader(timestamp);

          if (header != lastHeader) {
            items.add(header);
            lastHeader = header;
          }
          items.add(doc);
        }

        return ListView.builder(
          itemCount: items.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            if (item is String) {
              return _buildSectionHeader(item);
            }
            
            final doc = item as QueryDocumentSnapshot;
            final data = doc.data() as Map<String, dynamic>;
            return _buildNotificationItem(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF854F0B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String docId, Map<String, dynamic> data) {
    final bool isRead = data['isRead'] ?? false;
    final String type = data['type'] ?? 'info';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

    IconData icon;
    Color color;
    if (type == 'message') { icon = Icons.chat_bubble_outline; color = const Color(0xFFEF9F27); }
    else if (type == 'match') { icon = Icons.volunteer_activism; color = const Color(0xFF3B6D11); }
    else if (type == 'points') { icon = Icons.stars_rounded; color = const Color(0xFFEF9F27); }
    else { icon = Icons.notifications_none; color = const Color(0xFF185FA5); }

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red[400],
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => FirebaseFirestore.instance.collection('notifications').doc(docId).delete(),
      child: InkWell(
        onTap: () => _handleTap(docId, data),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? Colors.transparent : const Color(0xFFEF9F27).withValues(alpha: 0.05),
            border: const Border(bottom: BorderSide(color: Color(0xFFE8DDD0), width: 0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.1), 
                child: Icon(icon, color: color, size: 22)
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['title'] ?? 'Alert', 
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold, 
                              fontSize: 14,
                              color: const Color(0xFF2C2C2A)
                            )
                          ),
                        ),
                        if (timestamp != null) 
                          Text(
                            _getTimeAgo(timestamp), 
                            style: const TextStyle(fontSize: 11, color: Color(0xFFB4B2A9))
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['message'] ?? '', 
                      style: const TextStyle(fontSize: 13, color: Color(0xFF5F5E5A), height: 1.4)
                    ),
                  ],
                ),
              ),
              if (!isRead) 
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 12), 
                  width: 8, height: 8, 
                  decoration: const BoxDecoration(color: Color(0xFFEF9F27), shape: BoxShape.circle)
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(String docId, Map<String, dynamic> data) {
    FirebaseFirestore.instance.collection('notifications').doc(docId).update({'isRead': true});
    final type = data['type'];
    if (type == 'message') {
      Navigator.pop(context); 
    } else if (type == 'match' || type == 'request') {
      Navigator.pushNamed(context, '/waiting-list');
    } else if (type == 'points') {
      Navigator.pushNamed(context, '/profile');
    }
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) return "TODAY";
    if (itemDate == yesterday) return "YESTERDAY";
    
    const months = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  String _getTimeAgo(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFF1EFE8), shape: BoxShape.circle),
            child: Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          const Text('No notifications yet', style: TextStyle(color: Color(0xFF888780), fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          const Text('We\'ll alert you when something happens', style: TextStyle(color: Color(0xFFB4B2A9), fontSize: 13)),
        ],
      ),
    );
  }

  void _markAllAsRead() async {
    final batch = FirebaseFirestore.instance.batch();
    final snapshots = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: _userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (var doc in snapshots.docs) { batch.update(doc.reference, {'isRead': true}); }
    await batch.commit();
  }

  void _clearAll() async {
    final batch = FirebaseFirestore.instance.batch();
    final snapshots = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: _userId)
        .get();
    for (var doc in snapshots.docs) { batch.delete(doc.reference); }
    await batch.commit();
  }
}
