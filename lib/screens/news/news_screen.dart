import 'package:flutter/material.dart';
import 'package:news_api_flutter_package/model/article.dart';
import 'package:news_api_flutter_package/news_api_flutter_package.dart';

import 'article_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<Article>> _articlesFuture;

  @override
  void initState() {
    super.initState();
    _articlesFuture = NewsService().fetchTopHeadlines();
  }

  String _formatDate(String? dateTimeString) {
    if (dateTimeString == null) return '';

    // Parse the ISO 8601 date string
    final date = DateTime.parse(dateTimeString);
    return '${date.day}/${date.month}/${date.year}';
  }

  final List<String> categories = ['general', 'business', 'entertainment', 'health', 'science', 'sports', 'technology'];

  String _selectedCategory = 'general';

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _articlesFuture = NewsService().fetchTopHeadlines(category: category);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      categories.map((category) {
                        final isSelected = category == _selectedCategory;
                        final color = isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withOpacity(0.1);

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => _onCategorySelected(category),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
                                  boxShadow: isSelected ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))] : null,
                                ),
                                child: Text(
                                  category[0].toUpperCase() + category.substring(1).toLowerCase(),
                                  style: TextStyle(color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Article>>(
        future: _articlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No news found"));
          }

          final articles = snapshot.data!;

          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                child: InkWell(
                  onTap: () => _openArticle(context, article),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (article.urlToImage != null) ...[ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(article.urlToImage!, width: double.infinity, height: 150, fit: BoxFit.cover)), const SizedBox(height: 12)],
                        Text(article.title ?? 'No Title', style: Theme.of(context).textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Text(article.description ?? 'No Description', style: Theme.of(context).textTheme.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (article.source.name != null) ...[
                              Expanded(child: Text(article.source.name ?? '', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 8),
                            ],
                            if (article.publishedAt != null) ...[Text(_formatDate(article.publishedAt), style: TextStyle(color: Colors.grey[600], fontSize: 12))],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openArticle(BuildContext context, Article article) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ArticleDetailScreen(article: article)));
  }
}

class NewsService {
  final NewsAPI _newsAPI = NewsAPI(apiKey: 'bea38938fe5f4f0d8ae8b919d744cad8');

  Future<List<Article>> fetchTopHeadlines({String category = 'general', String country = 'us'}) async {
    try {
      final response = await _newsAPI.getTopHeadlines(country: country, category: category);
      print("Response Length: ${response.length}");
      for (var article in response) {
        print("Title: ${article.title}");
      }
      return response;
    } catch (e) {
      print("Error fetching headlines: $e");
      rethrow;
    }
  }
}
