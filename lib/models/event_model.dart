import '../services/auth_service.dart';

class EventModel {
  final int id;
  final String title;
  final String description;
  final DateTime? dateEvent;
  final String location;
  final String? imageUrl;
  final String category;
  final bool isConfirmed;
  final int participants;
  final String price;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.dateEvent,  
    required this.location,
    this.imageUrl,
    required this.category,
    required this.isConfirmed,
    required this.participants,
    required this.price,
  });

  /// Derives the Laravel public/storage base URL from the API baseUrl.
  /// e.g. "http://192.168.100.99:8000/api"
  ///   -> "http://192.168.100.99:8000/storage/events/image.jpg"
  static String? _buildImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final cleanPath = path.trim();

    // If the backend already returns a full URL, use it as-is.
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }

    final normalizedPath = cleanPath
        .replaceFirst(RegExp(r'^/?storage/'), '')
        .replaceFirst(RegExp(r'^/'), '');

    // Strip trailing "/api" or "/api/" from baseUrl and append "/storage/<path>"
    final storageBase =
        AuthService.baseUrl.replaceAll(RegExp(r'/api/?$'), '/storage/');
    return '$storageBase$normalizedPath';
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateEvent: json['date_event'] != null
          ? DateTime.tryParse(json['date_event'])
          : null,
      location: json['location'] ?? '',
      imageUrl: _buildImageUrl(json['image_url']),
      category: json['category'] ?? 'Académique',
      isConfirmed: json['isConfirmed'] ?? false,
      participants: json['participants'] ?? 0,
      price: json['price'] ?? 'Gratuit',
    );
  }
}