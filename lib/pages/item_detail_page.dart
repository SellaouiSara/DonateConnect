import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ItemDetailPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final String? itemId;

  const ItemDetailPage({super.key, required this.item, this.itemId});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  bool _isClaiming = false;

  Future<void> _markAsClaimed(BuildContext context) async {
    if (widget.itemId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Claimed?'),
        content: const Text('This will remove the item from the active feed. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B6D11)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isClaiming = true);
    try {
      await FirebaseFirestore.instance.collection('donations').doc(widget.itemId).update({'status': 'completed'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Item marked as claimed! +50 points'), backgroundColor: Color(0xFF3B6D11)));
        await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({'points': FieldValue.increment(50)});
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
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
          'Item details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF412402),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty)
              Image.network(
                item['imageUrl'],
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 220,
                  color: const Color(0xFFF1EFE8),
                  child: const Icon(Icons.broken_image, size: 64, color: Color(0xFFB4B2A9)),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 220,
                color: const Color(0xFFF1EFE8),
                child: const Icon(
                  Icons.card_giftcard,
                  size: 64,
                  color: Color(0xFFB4B2A9),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title'] ?? 'No title',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF412402),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3DE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item['condition'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF27500A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (item['location'] != null && item['location'] is GeoPoint) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Item Location'),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  height: 300,
                                  child: GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: LatLng(
                                        (item['location'] as GeoPoint).latitude,
                                        (item['location'] as GeoPoint).longitude,
                                      ),
                                      zoom: 14,
                                    ),
                                    markers: {
                                      Marker(
                                        markerId: const MarkerId('item_location'),
                                        position: LatLng(
                                          (item['location'] as GeoPoint).latitude,
                                          (item['location'] as GeoPoint).longitude,
                                        ),
                                      ),
                                    },
                                    zoomControlsEnabled: true,
                                    scrollGesturesEnabled: true,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close', style: TextStyle(color: Color(0xFFEF9F27))),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No precise location available.')));
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: Color(0xFFEF9F27)),
                            const SizedBox(width: 4),
                            Text(
                              item['distance'] ?? 'Nearby',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFEF9F27),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.star, size: 14, color: Color(0xFFEF9F27)),
                      const SizedBox(width: 4),
                      Text(
                        item['rating'] ?? '5.0',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888780),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE8DDD0), thickness: 0.5),
                  const SizedBox(height: 16),
                  const Text(
                    'About this item',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C2C2A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['description'] ?? 'This item is in great condition and barely used. The donor wants to make sure it goes to someone who truly needs it.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888780),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE8DDD0), thickness: 0.5),
                  const SizedBox(height: 16),
                  const Text(
                    'Donor',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C2C2A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFFAEEDA),
                        child: Text(
                          (item['donorName'] ?? item['donor'] ?? 'D').substring(0, 1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF854F0B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['donorName'] ?? item['donor'] ?? 'Anonymous Donor',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2C2C2A),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 12, color: Color(0xFFEF9F27)),
                              const SizedBox(width: 3),
                              Text(
                                item['rating'] ?? '5.0',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF888780),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Builder(builder: (context) {
                    final myId = FirebaseAuth.instance.currentUser?.uid;
                    final isOwner = myId == item['donorId'];
                    final isClaimed = item['status'] == 'completed';

                    if (isClaimed) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EFE8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('This item has been claimed',
                              style: TextStyle(fontSize: 15, color: Color(0xFF888780))),
                        ),
                      );
                    }

                    if (isOwner) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isClaiming ? null : () => _markAsClaimed(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B6D11),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isClaiming
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Mark as Claimed (+50 pts)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
                        ),
                      );
                    }

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/chat', arguments: {
                            'donorName': item['donorName'] ?? item['donor'] ?? 'Donor',
                            'recipientId': item['donorId'],
                            'isOwner': false,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF9F27),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Request this item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
