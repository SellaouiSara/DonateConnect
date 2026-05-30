import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  final bool showAsTab;

  const ProfilePage({super.key, this.showAsTab = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
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
    final userId = FirebaseAuth.instance.currentUser?.uid;

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
                'Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF412402),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF854F0B)),
                  onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
                ),
              ],
            ),
      body: userId == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading profile'));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Profile not found'));
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;
                String fullName = userData['FullName'] ?? userData['name'] ?? 'User';
                int points = userData['points'] ?? 0;
                String role = userData['role'] ?? 'individual';
                String email = userData['email'] ?? 'N/A';
                String initial = fullName.isNotEmpty
                    ? fullName.substring(0, 1).toUpperCase()
                    : 'U';

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header with profile info
                      Container(
                        width: double.infinity,
                        color: const Color(0xFFFAEEDA),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFFEF9F27),
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF412402),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF888780),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Color(0xFFEF9F27),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '4.9',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF854F0B),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAC775),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    role == 'organization'
                                        ? 'Verified Org'
                                        : 'Supporter',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF412402),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _statBox(points.toString(), 'Points'),
                                // Dynamic Donated Count
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('donations')
                                      .where('donorId', isEqualTo: userId)
                                      .snapshots(),
                                  builder: (context, dSnap) {
                                    int count = dSnap.hasData ? dSnap.data!.docs.length : 0;
                                    return _statBox(count.toString(), 'Donated');
                                  },
                                ),
                                // Dynamic Helped Count
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('donations')
                                      .where('donorId', isEqualTo: userId)
                                      .where('status', isEqualTo: 'completed')
                                      .snapshots(),
                                  builder: (context, hSnap) {
                                    int count = hSnap.hasData ? hSnap.data!.docs.length : 0;
                                    return _statBox(count.toString(), 'Helped');
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Points progress
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE8DDD0),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Next reward: Gold Champion',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2C2C2A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (points / 5000).clamp(0.0, 1.0),
                                  backgroundColor: const Color(0xFFF1EFE8),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFEF9F27),
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${5000 - points > 0 ? 5000 - points : 0} points to go',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF888780),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Profile Details Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE8DDD0),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Profile Information',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2C2C2A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _profileField('Full Name', fullName),
                              _profileField('Email', email),
                              _profileField(
                                'Role',
                                role == 'organization'
                                    ? 'Organization'
                                    : 'Individual',
                              ),
                              _profileField(
                                'Member Since',
                                userData['createdAt'] != null
                                    ? _formatDate(userData['createdAt'])
                                    : 'N/A',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Tabs for Donations and Requests
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: const Color(0xFFEF9F27),
                          unselectedLabelColor: const Color(0xFF888780),
                          indicatorColor: const Color(0xFFEF9F27),
                          tabs: [
                            const Tab(text: 'My Donations'),
                            Tab(text: role == 'organization' ? 'My Causes' : 'My Requests'),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 400,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildDonationsTab(userId),
                            role == 'organization' ? _buildCausesTab(userId) : _buildRequestsTab(userId),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Sign out button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                              }
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign out'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE24B4A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDonationsTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .where('donorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No donations yet',
                style: TextStyle(color: Color(0xFF888780)),
              ),
            ),
          );
        }

        final donations = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final data = donations[index].data() as Map<String, dynamic>;
            final docId = donations[index].id;
            return _donationCard(data, docId: docId);
          },
        );
      },
    );
  }

  Widget _buildCausesTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('causes')
          .where('orgId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No causes posted yet',
                style: TextStyle(color: Color(0xFF888780)),
              ),
            ),
          );
        }

        final causes = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: causes.length,
          itemBuilder: (context, index) {
            final data = causes[index].data() as Map<String, dynamic>;
            return _causeCard(data, docId: causes[index].id);
          },
        );
      },
    );
  }

  Widget _causeCard(Map<String, dynamic> cause, {String? docId}) {
    final title = cause['title'] ?? 'Unknown Cause';
    final goal = cause['itemsTotal'] ?? 0;
    final raised = cause['itemsReceived'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DDD0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2C2C2A),
                  ),
                ),
              ),
              if (docId != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _confirmDelete(context, 'causes', docId),
                  child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE24B4A)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal > 0 ? (raised / goal).clamp(0.0, 1.0) : 0,
              backgroundColor: const Color(0xFFF1EFE8),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B6D11)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$raised items raised of $goal goal',
            style: const TextStyle(fontSize: 11, color: Color(0xFF888780)),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('requesterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No requests yet',
                style: TextStyle(color: Color(0xFF888780)),
              ),
            ),
          );
        }

        final requests = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data = requests[index].data() as Map<String, dynamic>;
            return _requestCard(data, docId: requests[index].id);
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String collection, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE24B4A)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted'), backgroundColor: Color(0xFF888780)),
        );
      }
    }
  }

  Future<void> _markRequestCompleted(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(docId).update({'status': 'completed'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request marked as completed!'), backgroundColor: Color(0xFF3B6D11)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _donationCard(Map<String, dynamic> donation, {String? docId}) {
    final title = donation['title'] ?? 'Unknown';
    final category = donation['category'] ?? 'Other';
    final status = donation['status'] ?? 'available';
    final createdAt = donation['createdAt'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DDD0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2C2C2A))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: status == 'available' ? const Color(0xFFEAF3DE) : const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status, style: TextStyle(fontSize: 10, color: status == 'available' ? const Color(0xFF3B6D11) : const Color(0xFF633806), fontWeight: FontWeight.w500)),
              ),
              if (docId != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _confirmDelete(context, 'donations', docId),
                  child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE24B4A)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(category, style: const TextStyle(fontSize: 11, color: Color(0xFF888780))),
          const SizedBox(height: 6),
          Text(createdAt != null ? _formatDate(createdAt) : 'N/A', style: const TextStyle(fontSize: 10, color: Color(0xFFB4B2A9))),
        ],
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> request, {String? docId}) {
    final title = request['title'] ?? 'Unknown';
    final category = request['category'] ?? 'Other';
    final status = request['status'] ?? 'pending';
    final urgency = request['urgency'] ?? 'Standard';
    final createdAt = request['createdAt'];

    final urgencyColor = urgency == 'Emergency'
        ? const Color(0xFFE24B4A)
        : urgency == 'High'
            ? const Color(0xFFEF9F27)
            : const Color(0xFF888780);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DDD0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2C2C2A)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: urgencyColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(urgency, style: TextStyle(fontSize: 10, color: urgencyColor, fontWeight: FontWeight.w500)),
              ),
              if (docId != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _confirmDelete(context, 'requests', docId),
                  child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE24B4A)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                category,
                style: const TextStyle(fontSize: 11, color: Color(0xFF888780)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: status == 'approved'
                      ? const Color(0xFFEAF3DE)
                      : status == 'pending'
                          ? const Color(0xFFFAEEDA)
                          : const Color(0xFFFFEBE6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 9,
                    color: status == 'approved'
                        ? const Color(0xFF3B6D11)
                        : status == 'pending'
                            ? const Color(0xFF633806)
                            : const Color(0xFF9A3327),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                createdAt != null ? _formatDate(createdAt) : 'N/A',
                style: const TextStyle(fontSize: 10, color: Color(0xFFB4B2A9)),
              ),
              if (status != 'completed' && docId != null)
                GestureDetector(
                  onTap: () => _markRequestCompleted(docId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3DE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Mark Completed', style: TextStyle(fontSize: 10, color: Color(0xFF3B6D11), fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF888780)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C2C2A),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _statBox(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF412402),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF854F0B)),
        ),
      ],
    );
  }

  String _formatDate(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }
}
