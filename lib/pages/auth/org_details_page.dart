import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class OrgDetailsPage extends StatefulWidget {
  const OrgDetailsPage({super.key});

  @override
  State<OrgDetailsPage> createState() => _OrgDetailsPageState();
}

class _OrgDetailsPageState extends State<OrgDetailsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? _selectedOrgType;

  final List<String> _orgTypes = [
    'Charity',
    'NGO',
    'School',
    'Hospital',
    'Mosque / Church',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
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
          'Organization Details',
          style: TextStyle(
            color: Color(0xFF412402),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tell us about your organization',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF412402),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'This information will be shown on your public profile',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888780),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildLabel('Organization name'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'e.g. Hope Orphanage Foundation',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your organization name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Tax ID / Registration number'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _taxIdController,
                      hint: 'e.g. 123456789',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your tax ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Organization type'),
                    const SizedBox(height: 6),
                    _buildDropdown(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Phone number'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: _phoneController,
                                hint: '+213 XXX XXX XXX',
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('City'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: _cityController,
                                hint: 'e.g. Sétif',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Official address'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _addressController,
                      hint: 'Street, district, wilaya...',
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF9F27),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Next — upload documents',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'orgName': _nameController.text.trim(),
            'taxId': _taxIdController.text.trim(),
            'orgType': _selectedOrgType,
            'phoneNumber': _phoneController.text.trim(),
            'city': _cityController.text.trim(),
            'address': _addressController.text.trim(),
          });
          if (mounted) Navigator.pushNamed(context, '/org-upload');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      color: const Color(0xFFFAEEDA),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          _buildStep(number: '1', label: 'Account', done: true),
          _buildStepLine(filled: true),
          _buildStep(number: '2', label: 'Details', done: false, active: true),
          _buildStepLine(filled: false),
          _buildStep(number: '3', label: 'Documents', done: false),
        ],
      ),
    );
  }

  Widget _buildStep({
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
                color: active ? Colors.white : const Color(0xFF888780),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active || done
                ? const Color(0xFFEF9F27)
                : const Color(0xFFB4B2A9),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine({required bool filled}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: filled ? const Color(0xFFEF9F27) : const Color(0xFFD3CFC8),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF633806),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF2C2C2A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 13,
          color: Color(0xFFB4B2A9),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFD3CFC8),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFD3CFC8),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF9F27),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE24B4A),
            width: 1.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE24B4A),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedOrgType,
      hint: const Text(
        'Select organization type',
        style: TextStyle(fontSize: 13, color: Color(0xFFB4B2A9)),
      ),
      items: _orgTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedOrgType = value;
        });
      },
      validator: (value) {
        if (value == null) return 'Please select an organization type';
        return null;
      },
      decoration: InputDecoration(
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
      ),
    );
  }
}