import 'package:flutter/material.dart';
import 'package:open_ai/screens/ai/chat_image_screen.dart';
import 'package:open_ai/screens/ai/chat_screen.dart';

import '../ai/image_generate_screen.dart';
import '../demos/markdown_demo_screen.dart';
import '../demos/pinch_zoom_demo_screen.dart';
import '../news/news_screen.dart';

class DemoItem {
  final String title;
  final String description;
  final IconData icon;
  final Widget screen;

  DemoItem({required this.title, required this.description, required this.icon, required this.screen});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<DemoItem> _demoItems = [
    DemoItem(title: 'Pinch Zoom Demo', description: 'Demonstrates pinch-to-zoom functionality', icon: Icons.zoom_in, screen: PinchZoomDemoScreen()),
    DemoItem(title: 'Markdown Demo', description: 'Shows markdown rendering capabilities', icon: Icons.format_paint, screen: const MarkdownDemoScreen()),
    DemoItem(title: 'News Demo', description: 'Displays tech news articles', icon: Icons.newspaper, screen: const NewsScreen()),
    DemoItem(title: 'Chat Page', description: 'Open Ai Chat', icon: Icons.chat, screen: const ChatPage()),
    DemoItem(title: 'Image Page', description: 'Generate image', icon: Icons.image, screen: const ImageGenerateScreen()),
    DemoItem(title: 'Open AI', description: 'Chat & Image Generate', icon: Icons.art_track, screen: const ChatImageScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Demos", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), centerTitle: true, elevation: 0, backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _demoItems.length,
          itemBuilder: (context, index) {
            final item = _demoItems[index];
            return _buildDemoCard(context, item: item);
          },
        ),
      ),
    );
  }

  Widget _buildDemoCard(BuildContext context, {required DemoItem item}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.screen)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(item.icon, color: Theme.of(context).primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(item.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
