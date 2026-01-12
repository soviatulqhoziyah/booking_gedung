class Venue {
  final int? id; // Nullable karena saat Create, ID belum ada
  final String name;
  final String description;
  final String location;
  final int pricePerHour;
  final int capacity;
  final List<String> facilities;
  final List<String> images;

  Venue({
    this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.pricePerHour,
    required this.capacity,
    required this.facilities,
    required this.images,
  });

  // Mengubah JSON dari API menjadi Objek Dart
  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      location: json['location'],
      // Pastikan parsing ke integer aman
      pricePerHour: int.parse(json['price_per_hour'].toString().split('.')[0]),
      capacity: int.parse(json['capacity'].toString()),
      // Handle array JSON
      facilities: List<String>.from(json['facilities'] ?? []),
      images: List<String>.from(json['images'] ?? []),
    );
  }

  // Mengubah Objek Dart menjadi JSON untuk dikirim ke API
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'price_per_hour': pricePerHour,
      'capacity': capacity,
      // Kirim array sementara hardcode dulu biar gampang
      'facilities': ["AC", "Standard"],
      'images': ["placeholder.jpg"],
      'status': true,
    };
  }
}