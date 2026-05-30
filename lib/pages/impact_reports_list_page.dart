import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImpactReportsListPage extends StatelessWidget {
  const ImpactReportsListPage({super.key});

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
          'Impact Reports',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF412402)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('impact_reports')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFEF9F27)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome_outlined, size: 56, color: Color(0xFFD3CFC8)),
                  const SizedBox(height: 16),
                  const Text('No impact reports yet', style: TextStyle(color: Color(0xFF888780), fontSize: 15)),
                  const SizedBox(height: 8),
                  const Text('Organizations will publish them after completing a cause', style: TextStyle(color: Color(0xFFB4B2A9), fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _ReportCard(report: data);
            },
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final photos = List<String>.from(report['photos'] ?? []);
    final childrenHelped = report['childrenHelped'] ?? 0;
    final donorsCount = report['donorsCount'] ?? 0;
    final summary = report['summary'] ?? '';
    final orgName = report['orgName'] ?? 'Organization';
    final causeName = report['causeName'] ?? 'Cause';
    final date = report['date'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DDD0), width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo carousel
          if (photos.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: photos.length,
                  itemBuilder: (context, i) => Image.network(
                    photos[i],
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => Container(color: const Color(0xFFF1EFE8), child: const Icon(Icons.image, color: Color(0xFFD3CFC8), size: 48)),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 140,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF3DE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(child: Icon(Icons.verified, size: 48, color: Color(0xFF3B6D11))),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFEAF3DE), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Impact Report', style: TextStyle(fontSize: 10, color: Color(0xFF3B6D11), fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFFB4B2A9))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(causeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF412402))),
                const SizedBox(height: 4),
                Text('by $orgName', style: const TextStyle(fontSize: 12, color: Color(0xFF185FA5))),
                const SizedBox(height: 12),
                Text(summary, style: const TextStyle(fontSize: 13, color: Color(0xFF5F5E5A), height: 1.6)),
                const SizedBox(height: 16),
                // Stats
                Row(
                  children: [
                    _statChip(Icons.people, '$childrenHelped Helped'),
                    const SizedBox(width: 10),
                    _statChip(Icons.favorite, '$donorsCount Donors'),
                    if (photos.isNotEmpty) ...[ 
                      const SizedBox(width: 10),
                      _statChip(Icons.photo_library, '${photos.length} Photos'),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF1EFE8), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Color(0xFF854F0B)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF633806), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
