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
  /// e.g. "http://192.168.100.55/Classy-One/public/api"
  ///   -> "http://192.168.100.55/Classy-One/public/storage/"
  ///
  /// This means image URLs automatically follow whatever IP is set in
  /// AuthService.baseUrl — no hardcoded IPs anywhere.
  static String? _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;

    // If the backend already returns a full URL (future-proofing), use it as-is.
    if (path.startsWith('http')) return path;

    // Strip trailing "/api" from baseUrl and append "/storage/<path>"
    final storageBase =
        AuthService.baseUrl.replaceAll(RegExp(r'/api$'), '/storage/');
    return '$storageBase$path';
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

