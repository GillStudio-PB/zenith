// This screen provides an AI-powered assistant for users to ask questions related to UAE labor laws, financial advice, and more. It integrates with the Gemini API to generate responses and can automatically log transactions based on user input.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../env.dart';
import '../main.dart'; // import db
import '../db/models.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text':
          'Hello! I am your AI Assistant. You can ask me questions about UAE labor laws, financial advice, and more.'
    }
  ];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();

    try {
      if (Env.geminiApiKey == 'REPLACE_WITH_YOUR_GEMINI_API_KEY') {
        throw Exception("Please add your Gemini API Key in lib/env.dart");
      }

      final transactions = db.getTransactions();
      transactions.sort((a, b) => b.date.compareTo(a.date));
      final recentTxs = transactions.take(10).toList();

      final txContextStr = recentTxs.isEmpty
          ? "\n\n[System Note: User has no recent transactions.]"
          : "\n\n[System Note: User's last ${recentTxs.length} transactions: ${jsonEncode(recentTxs.map((t) => {
                'type': t.type,
                'amount': t.amount,
                'category': t.category,
                'date': t.date.millisecondsSinceEpoch
              }).toList())} ]";

      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=${Env.geminiApiKey}');

      http.Response? response;
      int retries = 3;

      while (retries > 0) {
        response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "system_instruction": {
              "parts": {
                "text":
                    "You are a helpful UAE labor law and financial assistant for workers in the UAE. Answer concisely and compassionately.\nIf the user asks to add or log a transaction (expense, income, or transfer), you MUST output a JSON block in the format:\n```json\n{\"action\": \"add_transaction\", \"amount\": 100, \"category\": \"Food\", \"description\": \"Groceries\", \"type\": \"expense\"}\n```\nThe type MUST be 'expense', 'income', or 'transfer'. You will receive the user's recent financials in the prompt to provide better financial advice. Always provide conversational feedback alongside any JSON."
              }
            },
            "contents": [
              {
                "parts": [
                  {"text": text + txContextStr}
                ]
              }
            ]
          }),
        );

        if (response.statusCode == 503 && retries > 1) {
          retries--;
          await Future.delayed(const Duration(seconds: 2));
        } else {
          break;
        }
      }

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String replyText = data['candidates'][0]['content']['parts'][0]['text'];
        String actionMessage = '';

        final regex = RegExp(r'```json\s*(\{[\s\S]*?\})\s*```');
        final match = regex.firstMatch(replyText);
        if (match != null) {
          try {
            final cmd = jsonDecode(match.group(1)!);
            if (cmd['action'] == 'add_transaction') {
              final newTx = AppTransaction(
                  type: cmd['type'] ?? 'expense',
                  amount: double.tryParse(cmd['amount'].toString()) ?? 0.0,
                  currency: 'AED',
                  category: cmd['category'] ?? 'Other',
                  description: cmd['description'] ?? '',
                  date: DateTime.now(),
                  notes: 'Added via AI Assistant');
              await db.putTransaction(newTx);
              actionMessage =
                  '\n\n✅ Automatically added transaction: ${newTx.type} of ${newTx.amount} AED for ${newTx.category}.';
            }
          } catch (e) {
            debugPrint("Failed to parse action json: $e");
          }
          replyText = replyText.replaceAll(match.group(0)!, '');
        }

        setState(() {
          _messages.add(
              {'role': 'assistant', 'text': replyText.trim() + actionMessage});
        });
      } else if (response != null && response.statusCode == 503) {
        throw Exception(
            "The friendly AI service is currently experiencing high demand. Please wait a moment and try again.");
      } else {
        throw Exception("Failed to connect to AI: ${response?.statusCode}");
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': 'Error: ${e.toString().replaceAll('Exception: ', '')}'
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AI Legal & Financial Assistant',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.amber)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.amber),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.amber.withValues(alpha: 0.2)
                          : Colors.grey.shade900,
                      border: Border.all(
                          color: isUser ? Colors.amber : Colors.white24),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser
                            ? const Radius.circular(16)
                            : const Radius.circular(4),
                        bottomRight: isUser
                            ? const Radius.circular(4)
                            : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 5,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.amber : Colors.white70,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.amber),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                  top: BorderSide(color: Colors.amber.withValues(alpha: 0.3))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ask a question...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                              color: Colors.amber.withValues(alpha: 0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Colors.amber),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade900,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.3),
                              blurRadius: 8)
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child:
                          const Icon(Icons.send, color: Colors.black, size: 20),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
