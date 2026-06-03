import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_list_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _isAdmin = userDoc.exists && userDoc.data()?['role'] == 'admin';
          _isLoading = false;
        });
        if (!_isAdmin) Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _approveRequest(String docId) async {
    await FirebaseFirestore.instance.collection('requests').doc(docId).update({'status': 'approved'});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request approved'), backgroundColor: Color(0xFF3B6D11)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_isAdmin) return const Scaffold(body: Center(child: Text('Unauthorized')));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFAF5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAEEDA),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFE24B4A)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          title: const Text('Admin Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF412402))),
          bottom: const TabBar(
            indicatorColor: Color(0xFFEF9F27),
            labelColor: Color(0xFFEF9F27),
            unselectedLabelColor: Color(0xFF888780),
            tabs: [
              Tab(text: 'Requests'),
              Tab(text: 'Organizations'),
              Tab(text: 'Messages'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RequestsTab(),
            _OrgsTab(),
            ChatListPage(),
          ],
        ),
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  Color _urgencyColor(String urgency) {
    if (urgency == 'Emergency') return const Color(0xFFE24B4A);
    if (urgency == 'High') return const Color(0xFFEF9F27);
    return const Color(0xFF888780);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Color(0xFFE24B4A))));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFEF9F27)));
        }
        // Sort client-side (avoids needing a composite Firestore index)
        final docs = snapshot.data!.docs
          ..sort((a, b) {
            final aTs = (a.data() as Map<String, dynamic>)['createdAt'];
            final bTs = (b.data() as Map<String, dynamic>)['createdAt'];
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return (bTs as Timestamp).compareTo(aTs as Timestamp);
          });
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFD3CFC8)),
                SizedBox(height: 12),
                Text('No pending requests', style: TextStyle(color: Color(0xFF888780))),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;

            final String itemTitle = data['title'] ?? data['item'] ?? 'No title';
            final String requesterId = data['requesterId'] ?? '';
            final String category = data['category'] ?? 'Uncategorised';
            final String reason = data['reason'] ?? data['description'] ?? 'No reason provided';
            final String urgency = data['urgency'] ?? 'Standard';
            final urgencyColor = _urgencyColor(urgency);

            // Format submission date
            String submittedAt = '';
            if (data['createdAt'] != null) {
              final ts = data['createdAt'] as Timestamp;
              final dt = ts.toDate();
              submittedAt = '${dt.day}/${dt.month}/${dt.year}';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8DDD0), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: avatar + real name (fetched from users collection) + urgency badge
                    Row(
                      children: [
                        FutureBuilder<DocumentSnapshot>(
                          future: requesterId.isNotEmpty
                              ? FirebaseFirestore.instance.collection('users').doc(requesterId).get()
                              : Future.value(null),
                          builder: (context, userSnap) {
                            String displayName = data['requesterName'] ?? data['name'] ?? 'Unknown user';
                            if (userSnap.hasData && userSnap.data != null && userSnap.data!.exists) {
                              final uData = userSnap.data!.data() as Map<String, dynamic>;
                              displayName = uData['FullName'] ?? uData['name'] ?? displayName;
                            }
                            final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFFFAEEDA),
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF854F0B),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2C2C2A),
                                      ),
                                    ),
                                    if (submittedAt.isNotEmpty)
                                      Text(
                                        'Submitted $submittedAt',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF888780)),
                                      ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: urgencyColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            urgency,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: urgencyColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF1EFE8)),
                    const SizedBox(height: 14),

                    // Item title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.card_giftcard_outlined, size: 16, color: Color(0xFFEF9F27)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Item needed', style: TextStyle(fontSize: 10, color: Color(0xFF888780))),
                              Text(
                                itemTitle,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF412402),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1EFE8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF5F5E5A)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Reason
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes_outlined, size: 16, color: Color(0xFF888780)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Reason', style: TextStyle(fontSize: 10, color: Color(0xFF888780))),
                              Text(
                                reason,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF5F5E5A),
                                  height: 1.4,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('requests')
                                  .doc(docId)
                                  .update({'status': 'rejected'});
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Request rejected'),
                                    backgroundColor: Color(0xFFE24B4A),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.close, size: 16, color: Color(0xFFE24B4A)),
                            label: const Text('Reject', style: TextStyle(color: Color(0xFFE24B4A))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE24B4A)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('requests')
                                  .doc(docId)
                                  .update({'status': 'approved'});
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Request approved ✓'),
                                    backgroundColor: Color(0xFF3B6D11),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check, size: 16, color: Colors.white),
                            label: const Text('Approve', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B6D11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OrgsTab extends StatelessWidget {
  const _OrgsTab();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'organization')
          .where('verificationStatus', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No pending organizations'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['FullName'] ?? data['name'] ?? 'Unknown Org'),
                subtitle: Text(data['email'] ?? 'No email'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B6D11)),
                  onPressed: () {
                    FirebaseFirestore.instance.collection('users').doc(docs[index].id).update({'verificationStatus': 'approved'});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Organization approved'), backgroundColor: Color(0xFF3B6D11))
                    );
                  },
                  child: const Text('Approve', style: TextStyle(color: Colors.white)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
