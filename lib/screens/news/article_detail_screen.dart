import 'package:flutter/material.dart';
import 'package:news_api_flutter_package/model/article.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(article.title ?? 'Article Details'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with source
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title ?? 'No Title', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 8),
                  if (article.source.name != null) Text(article.source.name!, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500)),
                ],
              ),

              // Image if available
              if (article.urlToImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      article.urlToImage!,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(height: 250, child: Center(child: Icon(Icons.error_outline, color: Colors.grey))),
                    ),
                  ),
                ),

              // Description
              Padding(padding: const EdgeInsets.only(top: 16.0), child: Text(article.description ?? 'No description available', style: Theme.of(context).textTheme.bodyLarge)),

              // Content
              if (article.content != null && article.content!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 16.0), child: Text(article.content!, style: Theme.of(context).textTheme.bodyMedium)),

              // Author and Published Date
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    if (article.author != null) Expanded(child: Text('By ${article.author}', style: TextStyle(color: Colors.grey[600], fontSize: 12))),
                    const SizedBox(width: 8),
                    if (article.publishedAt != null) Text(_formatDate(article.publishedAt), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateTimeString) {
    if (dateTimeString == null) return '';

    try {
      final date = DateTime.parse(dateTimeString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
