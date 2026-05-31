// ============================================================
// pages/waiting_list_page.dart
// Shows approved requests for users to browse and donate to.
// ============================================================
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WaitingListPage extends StatefulWidget {
  const WaitingListPage({super.key});

  @override
  State<WaitingListPage> createState() => _WaitingListPageState();
}

class _WaitingListPageState extends State<WaitingListPage> {
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Emergency',
    'High',
    'Medical',
    'Baby Items',
    'Education',
  ];

  Color _urgencyColor(String urgency) {
    if (urgency == 'Emergency') return const Color(0xFFE24B4A);
    if (urgency == 'High') return const Color(0xFFEF9F27);
    return const Color(0xFF888780);
  }

  @override
  Widget build(BuildContext context) {
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
          'Waiting list',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF412402),
          ),
        ),
      ),
      body: Column(
        children: [
          // info banner
          Container(
            width: double.infinity,
            color: const Color(0xFFFAEEDA),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: const Text(
              'These are real people with verified needs. Every request below was approved by an admin and supported with physical proof.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF854F0B),
                height: 1.5,
              ),
            ),
          ),
          // filter chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final bool selected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFEF9F27) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFEF9F27)
                            : const Color(0xFFD3CFC8),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF888780),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFEF9F27)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No requests available at the moment.',
                      style: TextStyle(color: Color(0xFF888780)),
                    ),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  if (_selectedFilter == 'All') return true;
                  final data = doc.data() as Map<String, dynamic>;
                  return data['urgency'] == _selectedFilter ||
                      data['category'] == _selectedFilter;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No requests match this filter.',
                      style: TextStyle(color: Color(0xFF888780)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final req = docs[index].data() as Map<String, dynamic>;
                    return _buildRequestCard(req);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    String name = req['name'] ?? req['requesterName'] ?? 'Unknown';
    String initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
    String days = req['days']?.toString() ?? 'Few';
    String urgency = req['urgency'] ?? 'Standard';
    String category = req['category'] ?? 'Other';
    String item = req['item'] ?? req['title'] ?? 'Item';
    String reason =
        req['reason'] ?? req['description'] ?? 'No description provided';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DDD0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFFAEEDA),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF854F0B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2C2C2A),
                      ),
                    ),
                    Text(
                      'Waiting $days days',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF888780),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _urgencyColor(urgency).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  urgency,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _urgencyColor(urgency),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF5F5E5A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Needs: $item',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF412402),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF888780),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                      'points': FieldValue.increment(200),
                    });
                  }
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Donated to ${name.split(' ')[0]}! +200 pts awarded.',
                      ),
                      backgroundColor: const Color(0xFF3B6D11),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF9F27),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Donate to ${name.split(' ')[0]}  +200 pts',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
