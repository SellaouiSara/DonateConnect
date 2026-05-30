// ============================================================
// pages/impact_report_page.dart
// Posted by organizations after receiving donations for a cause
// Proves transparency to the community
// ============================================================
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';

class ImpactReportPage extends StatefulWidget {
  final String causeName;
  final String orgName;
  final String? causeId;

  const ImpactReportPage({
    super.key,
    required this.causeName,
    required this.orgName,
    this.causeId,
  });

  @override
  State<ImpactReportPage> createState() => _ImpactReportPageState();
}

class _ImpactReportPageState extends State<ImpactReportPage> {
  // UI State
  bool _isWriting = false;
  bool _isLoading = false;
  bool _isFetching = true;

  // Controllers for the form
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _helpedController = TextEditingController();
  final TextEditingController _donorsController = TextEditingController();

  // Media handling
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // Data holder for viewing mode
  Map<String, dynamic> _reportData = {
    'summary': '',
    'childrenHelped': 0,
    'donorsCount': 0,
    'photos': [],
    'date': '',
  };

  @override
  void initState() {
    super.initState();
    _checkIfReportExists();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _helpedController.dispose();
    _donorsController.dispose();
    super.dispose();
  }

  /// 1. Fetch Existing Report
  /// Checks Firestore to see if this cause already has a published report.
  Future<void> _checkIfReportExists() async {
    if (widget.causeId == null) {
      setState(() {
        _isFetching = false;
        _isWriting = true;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('impact_reports')
          .doc(widget.causeId)
          .get();

      if (doc.exists) {
        setState(() {
          _reportData = doc.data()!;
          _isFetching = false;
          _isWriting = false;
        });
      } else {
        setState(() {
          _isFetching = false;
          _isWriting = true;
        });
      }
    } catch (e) {
      setState(() => _isFetching = false);
      debugPrint("Error fetching report: $e");
    }
  }

  /// 2. Pick Multiple Images
  /// Uses ImagePicker to let the organization pick photos from their device.
  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _selectedImages = images);
    }
  }

  /// 3. Submit Report (Upload to Storage + Save to Firestore)
  /// Handles the full flow of publishing a report.
  Future<void> _submitReport() async {
    if (_summaryController.text.trim().isEmpty || widget.causeId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a summary')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step A: Upload photos to Cloudinary and get URLs
      List<String> imageUrls = [];
      for (var image in _selectedImages) {
        String? url = await CloudinaryService.uploadImage(File(image.path));
        if (url != null) {
          imageUrls.add(url);
        }
      }

      // Step B: Construct and Save report data to Firestore
      final report = {
        'summary': _summaryController.text.trim(),
        'childrenHelped': int.tryParse(_helpedController.text) ?? 0,
        'donorsCount': int.tryParse(_donorsController.text) ?? 0,
        'photos': imageUrls,
        'date': DateTime.now().toString().split(' ')[0],
        'orgName': widget.orgName,
        'causeName': widget.causeName,
      };

      await FirebaseFirestore.instance
          .collection('impact_reports')
          .doc(widget.causeId)
          .set(report);

      // Step C: Update the original 'cause' to mark it as finished
      await FirebaseFirestore.instance
          .collection('causes')
          .doc(widget.causeId)
          .update({'hasImpactReport': true, 'status': 'completed'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report published!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // UI BUILDERS
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        title: Text(
          _isWriting ? 'Write impact report' : 'Impact report',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF412402),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderInfo(),
            const SizedBox(height: 20),
            if (_isWriting) _buildWritingForm() else _buildReportView(),
          ],
        ),
      ),
      bottomNavigationBar: _isWriting ? _buildBottomBar() : null,
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3DE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC0DD97), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: Color(0xFF3B6D11), size: 16),
              const SizedBox(width: 6),
              Text(
                widget.orgName,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF3B6D11),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.causeName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF27500A),
            ),
          ),
          if (!_isWriting)
            Text(
              'Published: ${_reportData['date']}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF888780)),
            ),
        ],
      ),
    );
  }

  Widget _buildReportView() {
    final List photos = _reportData['photos'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _statBox(
              '${_reportData['childrenHelped']}',
              'Helped',
              Icons.favorite,
              const Color(0xFFE24B4A),
            ),
            const SizedBox(width: 10),
            _statBox(
              '${_reportData['donorsCount']}',
              'Donors',
              Icons.people,
              const Color(0xFFEF9F27),
            ),
            const SizedBox(width: 10),
            _statBox(
              '${photos.length}',
              'Photos',
              Icons.photo_library,
              const Color(0xFF185FA5),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Summary',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C2C2A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _reportData['summary'],
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF888780),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        if (photos.isNotEmpty) ...[
          const Text(
            'Proof Photos',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C2C2A),
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  photos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF1EFE8),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Color(0xFF888780),
                            size: 24,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Unable to load',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF888780),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: const Color(0xFFF1EFE8),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFEF9F27),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildWritingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('People helped'),
        TextField(
          controller: _helpedController,
          keyboardType: TextInputType.number,
          decoration: _inputStyle('e.g. 30'),
        ),
        const SizedBox(height: 16),
        _label('Number of donors'),
        TextField(
          controller: _donorsController,
          keyboardType: TextInputType.number,
          decoration: _inputStyle('e.g. 14'),
        ),
        const SizedBox(height: 16),
        _label('What was achieved?'),
        TextField(
          controller: _summaryController,
          maxLines: 5,
          decoration: _inputStyle('Describe the impact of the donations...'),
        ),
        const SizedBox(height: 20),
        _label('Distribution Photos'),
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD3CFC8), width: 1),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.add_a_photo_outlined,
                  color: Color(0xFFEF9F27),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_selectedImages.length} photos selected',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888780),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF9F27),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Publish Impact Report',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF633806),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD3CFC8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD3CFC8)),
      ),
    );
  }

  Widget _statBox(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Color(0xFF888780)),
            ),
          ],
        ),
      ),
    );
  }
}
