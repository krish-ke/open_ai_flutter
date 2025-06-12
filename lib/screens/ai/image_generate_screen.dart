import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:open_ai/utils/app_colors.dart';
import 'package:pinch_zoom/pinch_zoom.dart';

class ImageGenerateScreen extends StatefulWidget {
  const ImageGenerateScreen({super.key});

  @override
  State<ImageGenerateScreen> createState() => _ImageGenerateScreenState();
}

class _ImageGenerateScreenState extends State<ImageGenerateScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final String apiKey = 'ddc-a4f-e1fbe58d4cb74e0e8f7c7f70e2b2aecc';
  final List<Map<String, String>> messages = [];

  bool _loading = false;
  bool _stopRequested = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> sendMessage(String prompt) async {
    if (prompt.trim().isEmpty || _loading) return;

    setState(() {
      messages.add({'role': 'user', 'content': prompt});
      messages.add({'role': 'generating', 'content': ''});
      _loading = true;
      _stopRequested = false;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      // Replace with your actual image generation endpoint & payload
      final response = await http.post(
        Uri.parse('https://api.a4f.co/v1/images/generations'),
        headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
        body: jsonEncode({'model': 'provider-3/dall-e-3', 'prompt': prompt, 'n': 1, 'size': '1024x1024'}),
      );

      if (_stopRequested) return;

      setState(() {
        messages.removeWhere((m) => m['role'] == 'generating');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Extract image URL(s) from the response
          final images = (data['data'] as List<dynamic>? ?? []).map((item) => item['url'] as String? ?? '').where((url) => url.isNotEmpty).toList();

          if (images.isNotEmpty) {
            // Add one message per image (or you could combine)
            for (var url in images) {
              messages.add({'role': 'assistant', 'content': url, 'type': 'image'});
            }
          } else {
            messages.add({'role': 'assistant', 'content': 'No image returned'});
          }
        } else {
          messages.add({'role': 'assistant', 'content': 'Error: ${response.statusCode}'});
        }

        _loading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _loading = false;
        messages.removeWhere((m) => m['role'] == 'generating');
        messages.add({'role': 'assistant', 'content': 'Error: $e'});
      });
    }
  }

  void stopResponse() {
    setState(() {
      _stopRequested = true;
      _loading = false;

      messages.removeWhere((m) => m['role'] == 'generating');

      // Remove last assistant message if it exists
      if (messages.isNotEmpty && messages.last['role'] == 'user') {
        messages.removeLast();
      }
    });
  }

  Widget _buildMessage(Map<String, String> message) {
    final role = message['role'];
    final content = message['content'] ?? '';
    final type = message['type'] ?? 'text'; // new field for differentiating content type

    if (role == 'generating') {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
          child: const Text("Generating...", style: TextStyle(fontStyle: FontStyle.italic)),
        ),
      );
    }

    final isUser = role == 'user';

    if (type == 'image') {
      // Show image bubble with copy URL button
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PinchZoom(
                  maxScale: 3.0,
                  onZoomStart: () {
                    print('Zoom started');
                  },
                  onZoomEnd: () {
                    print('Zoom ended');
                  },
                  child: Image.network(
                    content,
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(width: 250, height: 250, child: Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null)));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Image URL', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: content));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image URL copied to clipboard')));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Default: Text message with markdown for assistant, plain for user
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple : Colors.white,
          borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isUser ? 16 : 0), bottomRight: Radius.circular(isUser ? 0 : 16)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child:
            isUser
                ? Text(content, style: const TextStyle(color: Colors.white, fontStyle: FontStyle.normal))
                : MarkdownBody(
                  data: content,
                  styleSheet: MarkdownStyleSheet(
                    codeblockDecoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                    code: const TextStyle(fontFamily: 'Courier', fontSize: 14, color: Colors.greenAccent, backgroundColor: Colors.black87),
                    p: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('A4F AI Assistant'), backgroundColor: Colors.deepPurple, foregroundColor: AppColors.background),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: ListView.builder(controller: _scrollController, padding: const EdgeInsets.all(12), itemCount: messages.length, itemBuilder: (context, index) => _buildMessage(messages[index]))),
            const Divider(height: 1),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade300)),
                      child: TextField(
                        controller: _controller,
                        enabled: !_loading,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => sendMessage(_controller.text),
                        decoration: const InputDecoration(hintText: 'Ask me anything...', border: InputBorder.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _loading
                      ? ElevatedButton.icon(onPressed: stopResponse, icon: const Icon(Icons.stop), label: const Text("Stop"), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white))
                      : CircleAvatar(backgroundColor: Colors.deepPurple, child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () => sendMessage(_controller.text))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
