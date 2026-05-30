import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../cloudinary_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class OrgUploadPage extends StatefulWidget {
  const OrgUploadPage({super.key});

  @override
  State<OrgUploadPage> createState() => _OrgUploadPageState();
}

class _OrgUploadPageState extends State<OrgUploadPage> {
  String? _taxCert;
  String? _ngoReg;
  String? _authLetter;
  String? _proofOfAddress;
  bool _isLoadingSubmit = false;

  final Map<String, bool> _uploading = {
    'tax': false,
    'ngo': false,
    'auth': false,
    'proof': false,
  };

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUpload(String docKey) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() => _uploading[docKey] = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final String? downloadUrl = await CloudinaryService.uploadImage(File(image.path));
      if (downloadUrl == null) throw Exception('Failed to upload image to Cloudinary');

      setState(() {
        if (docKey == 'tax') _taxCert = downloadUrl;
        if (docKey == 'ngo') _ngoReg = downloadUrl;
        if (docKey == 'auth') _authLetter = downloadUrl;
        if (docKey == 'proof') _proofOfAddress = downloadUrl;
        _uploading[docKey] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload successful')),
        );
      }
    } catch (e) {
      setState(() => _uploading[docKey] = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e. Check your Firebase Storage rules.')),
        );
      }
    }
  }

  void _submitForReview() async {
    setState(() => _isLoadingSubmit = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'documents': {
            'taxCert': _taxCert,
            'ngoReg': _ngoReg,
            'authLetter': _authLetter,
            'proofOfAddress': _proofOfAddress,
          },
          'verificationStatus': 'pending',
          'role': 'organization', // Ensure role is set correctly
        });
        if (mounted) Navigator.pushReplacementNamed(context, '/pending');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingSubmit = false);
    }
  }

  bool get _canSubmit =>
      _taxCert != null && _ngoReg != null && _authLetter != null && _proofOfAddress != null && !_isLoadingSubmit;

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
          'Verification Documents',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF412402),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepIndicator(),
            const SizedBox(height: 24),
            const Text(
              'Upload your documents',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xFF412402),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'All 4 documents are required to get verified',
              style: TextStyle(fontSize: 13, color: Color(0xFF888780)),
            ),
            const SizedBox(height: 24),
            _uploadCard(
              label: 'Tax registration certificate',
              docKey: 'tax',
              url: _taxCert,
              isLoading: _uploading['tax'] ?? false,
            ),
            const SizedBox(height: 12),
            _uploadCard(
              label: 'NGO / Charity registration',
              docKey: 'ngo',
              url: _ngoReg,
              isLoading: _uploading['ngo'] ?? false,
            ),
            const SizedBox(height: 12),
            _uploadCard(
              label: 'Official authorization letter',
              docKey: 'auth',
              url: _authLetter,
              isLoading: _uploading['auth'] ?? false,
            ),
            const SizedBox(height: 12),
            _uploadCard(
              label: 'Proof of address',
              docKey: 'proof',
              url: _proofOfAddress,
              isLoading: _uploading['proof'] ?? false,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAEEDA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFAC775),
                  width: 0.5,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF854F0B), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Admin will review your documents within 2–3 business days',
                      style: TextStyle(fontSize: 12, color: Color(0xFF633806)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submitForReview : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF9F27),
                  disabledBackgroundColor: const Color(0xFFD3CFC8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoadingSubmit
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit for review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadCard({
    required String label,
    required String docKey,
    required String? url,
    required bool isLoading,
  }) {
    final bool uploaded = url != null;

    return GestureDetector(
      onTap: isLoading ? null : () => _pickAndUpload(docKey),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: uploaded ? const Color(0xFFEAF3DE) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: uploaded
                ? const Color(0xFFC0DD97)
                : const Color(0xFFD3CFC8),
            width: uploaded ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: uploaded
                    ? const Color(0xFFC0DD97)
                    : const Color(0xFFF1EFE8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFEF9F27),
                      ),
                    )
                  : Icon(
                      uploaded ? Icons.check : Icons.upload_file,
                      color: uploaded
                          ? const Color(0xFF27500A)
                          : const Color(0xFF888780),
                      size: 20,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: uploaded
                          ? const Color(0xFF27500A)
                          : const Color(0xFF2C2C2A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLoading
                        ? 'Uploading...'
                        : (uploaded ? 'Uploaded — tap to replace' : 'Tap to upload photo of document'),
                    style: TextStyle(
                      fontSize: 11,
                      color: uploaded
                          ? const Color(0xFF3B6D11)
                          : const Color(0xFFB4B2A9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _step(number: '1', label: 'Account', done: true),
          _line(filled: true),
          _step(number: '2', label: 'Details', done: true),
          _line(filled: true),
          _step(number: '3', label: 'Documents', active: true),
        ],
      ),
    );
  }

  Widget _step({
    required String number,
    required String label,
    bool done = false,
    bool active = false,
  }) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: done || active
                ? const Color(0xFFEF9F27)
                : const Color(0xFFD3CFC8),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: active
                    ? Colors.white
                    : const Color(0xFF888780),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: done || active
                ? const Color(0xFFEF9F27)
                : const Color(0xFFB4B2A9),
          ),
        ),
      ],
    );
  }

  Widget _line({required bool filled}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: filled
            ? const Color(0xFFEF9F27)
            : const Color(0xFFD3CFC8),
      ),
    );
  }
}
