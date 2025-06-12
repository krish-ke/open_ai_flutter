import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

class MarkdownDemoScreen extends StatelessWidget {
  const MarkdownDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Markdown Demo'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: MarkdownWidget(
                data: '''
# Markdown Demo

## Features
- **Bold text**
- *Italic text*
- ~~Strikethrough~~
- [Link](https://flutter.dev)

### Lists
1. First item
2. Second item
   - Sub item
   - Another sub item

### Code
```dart
void main() {
  print('Hello, Markdown!');
}
```

### Tables
| Column 1 | Column 2 |
|----------|----------|
| Data 1   | Data 2   |
| Data 3   | Data 4   |

### Images
![Flutter](https://images.pexels.com/photos/326055/pexels-photo-326055.jpeg?auto=compress&cs=tinysrgb&w=600)

> This is a blockquote
''',
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                config: MarkdownConfig(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
