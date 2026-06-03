import 'package:flutter/material.dart';
import 'post_donation_page.dart';
import 'request_help_page.dart';
import 'post_cause_page.dart';
import 'profile_page.dart';
import 'waiting_list_page.dart';
import 'causes_page.dart';
import 'chat_list_page.dart';
import 'notifications_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/time_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTab = 0;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  String _userRole = 'individual';

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        if (mounted) {
          setState(() {
            _userRole = (doc.data() as Map<String, dynamic>)['role'] ?? 'individual';
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFAF5),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PostDonationPage()),
            );
            return;
          }
          if (index == 2) {
            if (_userRole == 'organization') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostCausePage()),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RequestHelpPage()),
              );
            }
            return;
          }
          setState(() => _currentTab = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFEF9F27),
        unselectedItemColor: const Color(0xFFB4B2A9),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 8, //Adds shadow
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Donate',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.volunteer_activism_outlined),
            label: _userRole == 'organization' ? 'Post Cause' : 'Request',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.message_rounded),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_currentTab == 3) {
      return const ChatListPage();
    }
    if (_currentTab == 4) {
      return const ProfilePage(showAsTab: true);
    }
    return _buildFeed();
  }

  Widget _buildFeed() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildUrgentRequestsPreview(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(  //No refresh button needed
              stream: FirebaseFirestore.instance
                  .collection('donations')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 40),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading donations: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Retry'),
                          )
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFFD3CFC8)),
                        SizedBox(height: 16),
                        Text(
                          'No donations available yet',
                          style: TextStyle(color: Color(0xFF888780)),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['status'] == 'completed') return false; // Hide claimed items
                  
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  if (!title.contains(_searchQuery.toLowerCase())) return false;

                  final pref = data['preference'] ?? 'anyone';
                  if (pref == 'anyone') return true;
                  if (_userRole == 'organization' && pref == 'organizations') return true;
                  if (_userRole == 'individual' && pref == 'individuals') return true;
                  if (_userRole == 'admin') return true;
                  return false;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No matches found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    data['id'] = docs[index].id;
                    return _buildDonationCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      color: const Color(0xFFFAEEDA),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
            builder: (context, snapshot) {
              String name = "User";
              int points = 0;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                name = data['FullName'] ?? data['name'] ?? "User";
                points = data['points'] ?? 0;
              }
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Good morning,',
                          style: TextStyle(fontSize: 12, color: Color(0xFF854F0B)),
                        ),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF412402),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsPage()),
                      );
                    },
                    icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF854F0B)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAC775),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$points pts',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF412402),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD3CFC8),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFFB4B2A9), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search donations near you...',
                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFFB4B2A9)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WaitingListPage(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF9F27),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.format_list_bulleted,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Waiting list',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CausesPage()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEF9F27),
                        width: 1.0,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border,
                            color: Color(0xFFEF9F27), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Browse causes',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFEF9F27),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/item-detail', arguments: item);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8DDD0), width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: item['imageUrl'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image,
                                  color: Color(0xFFB4B2A9)),
                        ),
                      )
                    : const Icon(
                        Icons.card_giftcard,
                        color: Color(0xFF888780),
                        size: 28,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(                                          //Makes the donation list occupy all remaining space
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? 'No title',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2C2C2A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1EFE8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item['condition'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF5F5E5A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Nearby',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF888780),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      TimeUtils.formatTimeAgo(item['createdAt']),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFB4B2A9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFD3CFC8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgentRequestsPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Urgent Requests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF412402),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/waiting-list'),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEF9F27),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('requests')
                .where('status', isEqualTo: 'approved')
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFEF9F27)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No urgent requests at the moment', style: TextStyle(color: Color(0xFF888780), fontSize: 12)));
              }
              
              final docs = snapshot.data!.docs;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final req = docs[index].data() as Map<String, dynamic>;
                  return Container(
                    width: 240,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEF9F27), width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF9F27).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                req['urgency'] ?? 'High',
                                style: const TextStyle(fontSize: 10, color: Color(0xFFEF9F27), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                req['item'] ?? req['title'] ?? 'Item needed',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF412402)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          req['reason'] ?? req['description'] ?? '',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF888780)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/waiting-list'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF9F27),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            minimumSize: const Size(double.infinity, 30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Donate +200 pts', style: TextStyle(fontSize: 11, color: Colors.white)),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
