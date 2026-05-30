// ============================================================
// pages/auth/pending_page.dart
// ============================================================
import 'package:flutter/material.dart';

class PendingPage extends StatelessWidget {
  const PendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFAF5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEEDA),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEF9F27),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.hourglass_top,
                  color: Color(0xFFEF9F27),
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Under review',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF412402),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your documents have been submitted. Our admin team will verify your organization within 2–3 business days.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF888780), height: 1.6),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3DE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFC0DD97), width: 0.5),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Documents submitted',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF27500A),
                      ),
                    ),
                    SizedBox(height: 10),
                    _DocRow(label: 'Tax certificate', done: true),
                    _DocRow(label: 'NGO registration', done: true),
                    _DocRow(label: 'Authorization letter', done: true),
                    _DocRow(label: 'Proof of address', done: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD3CFC8), width: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Browse as guest meanwhile',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF888780),
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
}

class _DocRow extends StatelessWidget {
  final String label;
  final bool done;

  const _DocRow({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: done
                ? const Color(0xFF3B6D11)
                : const Color(0xFFB4B2A9),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: done
                  ? const Color(0xFF3B6D11)
                  : const Color(0xFFB4B2A9),
            ),
          ),
        ],
      ),
    );
  }
}