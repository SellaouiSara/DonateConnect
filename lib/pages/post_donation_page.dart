import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart';
import 'dart:io';
import 'map_selection_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PostDonationPage extends StatefulWidget {
  const PostDonationPage({super.key});

  @override
  State<PostDonationPage> createState() => _PostDonationPageState();
}

class _PostDonationPageState extends State<PostDonationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  String? _selectedCategory;
  String _selectedCondition = '';
  String _selectedPreference = 'anyone';
  bool _isLoading = false;
  LatLng? _selectedLocation;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _realMatches = [];

  final List<String> _categories = [
    'Clothing',
    'Medical',
    'Baby Items',
    'Education',
    'Electronics',
    'Household',
    'Food',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }
  Future<void> pickAndUploadImage() async {

    final XFile? pickedFile =
    await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);

    String? imageUrl =
    await CloudinaryService.uploadImage(imageFile);

    if (imageUrl != null) {

      print(imageUrl);

    } else {

      print('Upload failed');
    }
  }
  Future<void> _findMatches(String? category) async {
    if (category == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('requests')
        .where('status', isEqualTo: 'approved')
        .where('category', isEqualTo: category)
        .limit(2)
        .get();

    setState(() {
      _realMatches = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    });
  }

  Future<String?> _uploadImage(String userId) async {
    if (_imageFile == null) return null;
    try {
      return await CloudinaryService.uploadImage(_imageFile!);
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  void _handlePost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCondition.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select item condition')));
      return;
    }
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a photo of the item')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? imageUrl = await _uploadImage(user.uid);

      await FirebaseFirestore.instance.collection('donations').add({
        'donorId': user.uid,
        'donorName': user.displayName ?? 'Anonymous',
        'title': _titleController.text.trim(),
        'category': _selectedCategory,
        'description': _descController.text.trim(),
        'condition': _selectedCondition,
        'preference': _selectedPreference,
        'imageUrl': imageUrl,
        'location': _selectedLocation != null ? GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude) : null,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Award points for posting
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'points': FieldValue.increment(10),
      });

      if (!mounted) return;

      if (_realMatches.isNotEmpty) {
        _showMatchPopup();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation posted! +10 points earned'), backgroundColor: Color(0xFF3B6D11)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMatchPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: const BoxDecoration(color: Color(0xFFFAEEDA), shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_active, color: Color(0xFFEF9F27), size: 26),
                ),
                const SizedBox(height: 14),
                const Text('Someone is waiting for this!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('${_realMatches.length} people need exactly what you\'re donating. Donate directly and earn +150 bonus points.',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF888780))),
                const SizedBox(height: 16),
                ..._realMatches.map((match) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFFF8EE), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFAC775), width: 0.5)),
                  child: Row(children: [
                    CircleAvatar(radius: 18, backgroundColor: const Color(0xFFEF9F27), child: Text((match['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(match['name'] ?? 'Anonymous', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      Text(match['reason'] ?? 'Needs help', style: const TextStyle(fontSize: 11, color: Color(0xFF888780)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                  ]),
                )),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () { Navigator.pop(context); Navigator.pushNamed(context, '/waiting-list'); },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF9F27), minimumSize: const Size(double.infinity, 45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Donate to waiting list +150 pts', style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                  child: const Text('Post without targeting', style: TextStyle(color: Color(0xFF888780))),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAEEDA), elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF854F0B)), onPressed: () => Navigator.pop(context)),
        title: const Text('Post a donation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF412402))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Item Photo'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD3CFC8), width: 0.5),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: Color(0xFFB4B2A9), size: 40),
                            SizedBox(height: 8),
                            Text('Upload item photo', style: TextStyle(color: Color(0xFFB4B2A9), fontSize: 13)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              _label('Item title'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: _inputStyle('e.g. Wheelchair in good condition'),
                validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              _label('Category'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) {
                   setState(() => _selectedCategory = val);
                   _findMatches(val);
                },
                decoration: _inputStyle('Select category'),
              ),
              const SizedBox(height: 16),
              _label('Description'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: _inputStyle('Describe the item...'),
                validator: (v) => v!.length < 10 ? 'Description too short' : null,
              ),
              const SizedBox(height: 16),
              _label('Condition'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['New', 'Like new', 'Used', 'Damaged'].map((c) => _conditionChip(c)).toList(),
              ),
              const SizedBox(height: 20),
              _label('Location'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapSelectionPage()),
                  );
                  if (result != null && result is LatLng) {
                    setState(() {
                      _selectedLocation = result;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD3CFC8)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFEF9F27), size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _selectedLocation == null ? 'Tap to select location on map' : 'Location selected',
                        style: TextStyle(color: _selectedLocation == null ? const Color(0xFFB4B2A9) : const Color(0xFF412402), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _label('Who can request this?'),
              const SizedBox(height: 6),
              _preferenceRadio('anyone', 'Anyone'),
              _preferenceRadio('individuals', 'Individuals only'),
              _preferenceRadio('organizations', 'Organizations only'),
              const SizedBox(height: 16),
              
              if (_realMatches.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3DE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC0DD97), width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people, color: Color(0xFF3B6D11), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${_realMatches.length} people are waiting for this item',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF27500A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._realMatches.map((match) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          CircleAvatar(radius: 16, backgroundColor: const Color(0xFFE8DDD0), child: Text((match['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Color(0xFF854F0B), fontSize: 12))),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${match['name'] ?? 'Anonymous'} — ${(match['createdAt'] as Timestamp?) != null ? DateTime.now().difference((match['createdAt'] as Timestamp).toDate()).inDays : 0} days waiting', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF412402))),
                            Text(match['reason'] ?? 'Needs help', style: const TextStyle(fontSize: 10, color: Color(0xFF888780)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ])),
                        ]),
                      )),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/waiting-list'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B6D11), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          child: const Text('View full waiting list +150 bonus pts', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EFE8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_outlined, color: Color(0xFF888780), size: 16),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Every request on this list was reviewed and approved by an admin, backed by real physical proof like medical documents or official papers. You are donating to people with verified needs — not strangers from the Internet.',
                          style: TextStyle(fontSize: 10, color: Color(0xFF5F5E5A), height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handlePost,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF9F27), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Post donation', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conditionChip(String label) {
    final bool selected = _selectedCondition == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCondition = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF8EE) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFFEF9F27) : const Color(0xFFD3CFC8), width: selected ? 1.5 : 0.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: selected ? const Color(0xFF412402) : const Color(0xFF888780))),
      ),
    );
  }

  Widget _preferenceRadio(String value, String title) {
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: const Color(0xFFD3CFC8),
      ),
      child: RadioListTile<String>(
        title: Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF888780))),
        value: value,
        groupValue: _selectedPreference,
        activeColor: const Color(0xFFEF9F27),
        contentPadding: EdgeInsets.zero,
        dense: true,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        onChanged: (val) {
          if (val != null) setState(() => _selectedPreference = val);
        },
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF633806)));
  InputDecoration _inputStyle(String hint) => InputDecoration(
    hintText: hint, filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD3CFC8))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD3CFC8))),
  );
}
