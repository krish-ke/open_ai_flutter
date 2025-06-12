import 'package:flutter/material.dart';
import 'package:pinch_zoom/pinch_zoom.dart';

class PinchZoomDemoScreen extends StatelessWidget {
  const PinchZoomDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pinch Zoom Demo'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: Center(
        child: PinchZoom(
          maxScale: 3.0,
          onZoomStart: () {
            print('Zoom started');
          },
          onZoomEnd: () {
            print('Zoom ended');
          },
          child: Image.network('https://images.pexels.com/photos/326055/pexels-photo-326055.jpeg?auto=compress&cs=tinysrgb&w=600', height: 300, width: double.infinity, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
