// This screen displays information about the developer, including contact details and app version. It allows users to copy contact information to the clipboard and provides a brief description of the developer's company.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _copyToClipboard(BuildContext context, String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$type copied to clipboard!'),
      backgroundColor: Colors.white,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('About Developer',
            style: TextStyle(
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
                color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo / Glyph area
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 10),
                ],
              ),
              child: const Icon(
                Icons.electric_bolt_rounded,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'GILL INFOTECH',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'CREATING DIGITAL EXPERIENCES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 48),

            // Developer Details Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  Text(
                    'DEVELOPER',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Preet Gill',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.5),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Divider(
                        color: Colors.white.withValues(alpha: 0.15), height: 1),
                  ),
                  _ContactRow(
                    icon: Icons.phone_android_rounded,
                    label: 'Contact',
                    value: '+91-9988995291',
                    onTap: () => _copyToClipboard(
                        context, '+919988995291', 'Phone number'),
                  ),
                  const SizedBox(height: 20),
                  _ContactRow(
                    icon: Icons.alternate_email_rounded,
                    label: 'Email',
                    value: 'Preetuae15@gmail.com',
                    onTap: () => _copyToClipboard(
                        context, 'Preetuae15@gmail.com', 'Email address'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.forum_rounded,
                      color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Get In Touch',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          'Feel free to contact us for queries, suggestions, and feedback.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.4,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text('Zenith App • Version 5.1.1A\nUpdate date: 19-06-2026',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12)),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.15), size: 16),
          ],
        ),
      ),
    );
  }
}
