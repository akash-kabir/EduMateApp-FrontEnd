class PoiModel {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String description;
  final String imageUrl;
  final String address;
  final String type;

  PoiModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.description = '',
    this.imageUrl = '',
    this.address = '',
    this.type = 'Campus',
  });

  factory PoiModel.fromJson(Map<String, dynamic> json) {
    return PoiModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      lat: (json['location'] != null && json['location']['lat'] != null)
          ? (json['location']['lat'] as num).toDouble()
          : 0.0,
      lng: (json['location'] != null && json['location']['lng'] != null)
          ? (json['location']['lng'] as num).toDouble()
          : 0.0,
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      address: json['address'] ?? '',
      type: json['type'] ?? 'Campus',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'name': name,
      'location': {
        'lat': lat,
        'lng': lng,
      },
      'description': description,
      'imageUrl': imageUrl,
      'address': address,
      'type': type,
    };
  }
}
