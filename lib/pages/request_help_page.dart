// ============================================================
// pages/request_help_page.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class RequestHelpPage extends StatefulWidget {
  const RequestHelpPage({super.key});

  @override
  State<RequestHelpPage> createState() => _RequestHelpPageState();
}

class _RequestHelpPageState extends State<RequestHelpPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  String? _selectedCategory;
  String _selectedUrgency = 'Standard';
  bool _isLoading = false;


  final List<String> _categories = [
    'Clothing', 'Medical', 'Baby Items',
    'Education', 'Electronics', 'Household', 'Food', 'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      String name = FirebaseAuth.instance.currentUser!.displayName ?? 'Anonymous';
      await FirebaseFirestore.instance.collection('requests').add({
        'requesterId': uid,
        'requesterName': name,
        'title': _titleController.text.trim(),
        'category': _selectedCategory,
        'reason': _reasonController.text.trim(),
        'urgency': _selectedUrgency,
        'status': 'pending',
        'proofPhotos': [],
        'priorityScore': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted. Admin will review it soon.')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
          'Request help',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF412402),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('What do you need?'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF2C2C2A)),
                decoration: _inputStyle('e.g. Need baby stroller for newborn'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter what you need';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _label('Category'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                hint: const Text(
                  'Select category',
                  style: TextStyle(fontSize: 13, color: Color(0xFFB4B2A9)),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (v) => v == null ? 'Please select a category' : null,
                decoration: _inputStyle(''),
              ),
              const SizedBox(height: 16),
              _label('Why do you need this?'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _reasonController,
                maxLines: 5,
                style: const TextStyle(fontSize: 14, color: Color(0xFF2C2C2A)),
                decoration: _inputStyle(
                  'Explain your situation. The more details you provide, the faster your request gets approved...',
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 30) {
                    return 'Please write at least 30 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _label('Urgency level'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _urgencyChip('Standard', const Color(0xFF888780)),
                  const SizedBox(width: 8),
                  _urgencyChip('High', const Color(0xFFEF9F27)),
                  const SizedBox(width: 8),
                  _urgencyChip('Emergency', const Color(0xFFE24B4A)),
                ],
              ),
              const SizedBox(height: 16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF854F0B), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your request will be reviewed by an admin before being added to the waiting list. You will be notified once approved.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF633806),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF9F27),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Submit request',
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
      ),
    );
  }

  Widget _urgencyChip(String label, Color color) {
    final bool selected = _selectedUrgency == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedUrgency = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : const Color(0xFFD3CFC8),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? color : const Color(0xFF888780),
            fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF633806),
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB4B2A9)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD3CFC8), width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD3CFC8), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF9F27), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE24B4A), width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE24B4A), width: 1.5),
      ),
    );
  }
}