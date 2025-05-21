import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsService {
  static const String _baseUrl = 'https://newsapi.org/v2';
  final String _apiKey;

  NewsService() : _apiKey = dotenv.env['NEWS_API_KEY'] ?? '';

  Future<List<NewsArticle>> getTopHeadlines({String? category}) async {
    try {
      final queryParams = {
        'country': 'us',
        'apiKey': _apiKey,
        if (category != null) 'category': category,
      };

      final uri = Uri.parse('$_baseUrl/top-headlines').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;
        return articles.map((article) => NewsArticle.fromJson(article)).toList();
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load news: $e');
    }
  }

  Future<List<NewsArticle>> searchNews(String query) async {
    try {
      final queryParams = {
        'q': query,
        'apiKey': _apiKey,
      };

      final uri = Uri.parse('$_baseUrl/everything').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;
        return articles.map((article) => NewsArticle.fromJson(article)).toList();
      } else {
        throw Exception('Failed to search news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search news: $e');
    }
  }
}

class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String? imageUrl;
  final String source;
  final DateTime publishedAt;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    this.imageUrl,
    required this.source,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['urlToImage'],
      source: json['source']['name'] ?? '',
      publishedAt: DateTime.parse(json['publishedAt']),
    );
  }
} 