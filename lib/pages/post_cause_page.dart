// ============================================================
// pages/post_cause_page.dart
// Only for verified organizations
// ============================================================
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostCausePage extends StatefulWidget {
  const PostCausePage({super.key});

  @override
  State<PostCausePage> createState() => _PostCausePageState();
}

class _PostCausePageState extends State<PostCausePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();

  // each item need is a map with name and quantity
  final List<Map<String, TextEditingController>> _itemControllers = [
    {
      'item': TextEditingController(),
      'qty': TextEditingController(),
    }
  ];

  String _selectedUrgency = 'Standard';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _deadlineController.dispose();
    for (var pair in _itemControllers) {
      pair['item']!.dispose();
      pair['qty']!.dispose();
    }
    super.dispose();
  }

  void _addItemRow() {
    setState(() {
      _itemControllers.add({
        'item': TextEditingController(),
        'qty': TextEditingController(),
      });
    });
  }

  void _removeItemRow(int index) {
    if (_itemControllers.length == 1) return;
    setState(() {
      _itemControllers[index]['item']!.dispose();
      _itemControllers[index]['qty']!.dispose();
      _itemControllers.removeAt(index);
    });
  }

  Future<void> _handlePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("You must be logged in to post a cause.");
      }

      // Fetch organization name from Firestore user profile
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final orgName = userDoc.data()?['orgName'] ?? 'Verified Organization';

      List<String> itemsNeededStrings = [];
      int totalItemsCount = 0;

      for (var pair in _itemControllers) {
        final name = pair['item']!.text.trim();
        final qtyStr = pair['qty']!.text.trim();
        final qty = int.tryParse(qtyStr) ?? 0;
        
        if (name.isNotEmpty) {
          itemsNeededStrings.add('$qty $name');
          totalItemsCount += qty;
        }
      }

      if (itemsNeededStrings.isEmpty) {
        throw Exception("Please add at least one item.");
      }

      await FirebaseFirestore.instance.collection('causes').add({
        'org': orgName,
        'orgId': user.uid,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'itemsNeeded': itemsNeededStrings,
        'itemsReceived': 0,
        'itemsTotal': totalItemsCount,
        'deadline': _deadlineController.text.trim(),
        'urgent': _selectedUrgency == 'Emergency',
        'urgencyLevel': _selectedUrgency,
        'hasImpactReport': false,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cause posted successfully! Donors will be notified.'),
            backgroundColor: Color(0xFF3B6D11),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          'Post a cause',
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
              // org only notice
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFB5D4F4),
                    width: 0.5,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, color: Color(0xFF185FA5), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This is visible to all users. They can donate items directly to your cause. You must post an impact report after receiving donations.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0C447C),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _label('Cause title'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                enabled: !_isLoading,
                style: const TextStyle(fontSize: 14, color: Color(0xFF2C2C2A)),
                decoration: _inputStyle(
                  'e.g. Winter preparation for 30 children',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _label('Description'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                enabled: !_isLoading,
                maxLines: 4,
                style: const TextStyle(fontSize: 14, color: Color(0xFF2C2C2A)),
                decoration: _inputStyle(
                  'Explain the cause, who it helps, why it matters...',
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 30) {
                    return 'Please write at least 30 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _label('Items needed'),
              const SizedBox(height: 6),
              // dynamic list of item rows
              ...List.generate(_itemControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _itemControllers[index]['item'],
                          enabled: !_isLoading,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2C2C2A),
                          ),
                          decoration: _inputStyle('Item name'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _itemControllers[index]['qty'],
                          enabled: !_isLoading,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2C2C2A),
                          ),
                          decoration: _inputStyle('Qty'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return '?';
                            }
                            if (int.tryParse(v) == null) return '!';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isLoading ? null : () => _removeItemRow(index),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1EFE8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.remove,
                            color: Color(0xFF888780),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              GestureDetector(
                onTap: _isLoading ? null : _addItemRow,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFEF9F27),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: const Color(0xFFEF9F27), size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Add another item',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFEF9F27),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _label('Urgency'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  _urgencyChip('Standard', const Color(0xFF888780)),
                  _urgencyChip('High', const Color(0xFFEF9F27)),
                  _urgencyChip('Emergency', const Color(0xFFE24B4A)),
                ],
              ),
              const SizedBox(height: 16),
              _label('Deadline (optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _deadlineController,
                enabled: !_isLoading,
                style: const TextStyle(fontSize: 14, color: Color(0xFF2C2C2A)),
                decoration: _inputStyle('e.g. November 15, 2025'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handlePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF9F27),
                    disabledBackgroundColor: const Color(0xFFD3CFC8),
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
                          'Post cause',
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
      onTap: _isLoading ? null : () => setState(() => _selectedUrgency = label),
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
