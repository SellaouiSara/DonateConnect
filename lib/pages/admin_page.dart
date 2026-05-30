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
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No pending requests'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['item'] ?? 'Item'),
                subtitle: Text('By: ${data['userName'] ?? 'User'}'),
                trailing: ElevatedButton(
                  onPressed: () => FirebaseFirestore.instance.collection('requests').doc(docs[index].id).update({'status': 'approved'}),
                  child: const Text('Approve'),
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
