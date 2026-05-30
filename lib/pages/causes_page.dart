import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'impact_report_page.dart';
import 'chat_page.dart';
import 'impact_reports_list_page.dart';

class CausesPage extends StatefulWidget {
  final bool showAsTab;

  const CausesPage({super.key, this.showAsTab = false});

  @override
  State<CausesPage> createState() => _CausesPageState();
}

class _CausesPageState extends State<CausesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFAF5),
      appBar: widget.showAsTab
          ? null
          : AppBar(
              backgroundColor: const Color(0xFFFAEEDA),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF854F0B)),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Organization causes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF412402),
                ),
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.showAsTab)
              Container(
                width: double.infinity,
                color: const Color(0xFFFAEEDA),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Organization causes',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF412402))),
                          const Text('Support verified organizations directly',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF854F0B))),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ImpactReportsListPage())),
                            child: const Row(
                              children: [
                                Icon(Icons.auto_awesome,
                                    size: 13, color: Color(0xFF3B6D11)),
                                SizedBox(width: 4),
                                Text('View impact reports',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF3B6D11),
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.underline)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          if (data['role'] == 'organization') {
                            return GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/post-cause'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF9F27),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Post cause',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        }
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('causes')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading causes: ${snapshot.error}'),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.volunteer_activism_outlined,
                            size: 48,
                            color: Color(0xFFD3CFC8),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No active causes yet',
                            style: TextStyle(color: Color(0xFF888780)),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      data['id'] = docs[index].id;
                      return _buildCauseCard(data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCauseCard(Map<String, dynamic> cause) {
    final int received = cause['itemsReceived'] ?? 0;
    final int total = (cause['itemsTotal'] ?? 1) == 0
        ? 1
        : (cause['itemsTotal'] ?? 1);
    final double progress = (received / total).clamp(0.0, 1.0);
    final bool isUrgent = cause['urgent'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? const Color(0xFFF0997B) : const Color(0xFFE8DDD0),
          width: isUrgent ? 1.0 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUrgent)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAECE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 12, color: Color(0xFF993C1D)),
                    SizedBox(width: 4),
                    Text(
                      'Urgent',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF993C1D),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F1FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.apartment,
                    color: Color(0xFF185FA5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cause['org'] ?? 'Organization',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF185FA5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 12,
                            color: Color(0xFF185FA5),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF888780),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  cause['deadline'] != null &&
                          cause['deadline'].toString().isNotEmpty
                      ? 'Due: ${cause['deadline']}'
                      : 'Ongoing',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFB4B2A9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              cause['title'] ?? 'No Title',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF412402),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cause['description'] ?? '',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5F5E5A),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            // Items needed tags
            if (cause['itemsNeeded'] != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (cause['itemsNeeded'] as List<dynamic>).map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EFE8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF5F5E5A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
            // Progress Bar Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$received items of ${cause['itemsTotal'] ?? 0} received',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF888780),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B6D11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFF1EFE8),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF639922),
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Navigate to chat with organization
                      final orgId = cause['orgId'];
                      final orgName = cause['org'] ?? 'Organization';

                      if (orgId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Could not find organization contact info')),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            donorName: orgName,
                            recipientId: orgId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF9F27),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Donate items',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (cause['hasImpactReport'] == true) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImpactReportPage(
                          causeName: cause['title'] ?? 'Cause',
                          orgName: cause['org'] ?? 'Organization',
                          causeId: cause['id'],
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3DE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC0DD97)),
                      ),
                      child: const Text(
                        'Impact report',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF27500A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
