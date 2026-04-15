// Hotel model representing a hotel property
class Hotel {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final String location;
  final double rating;
  final List<Room> rooms;
  final List<String> amenities;

  const Hotel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.location,
    required this.rating,
    required this.rooms,
    required this.amenities,
  });
}

// Room model representing a room within a hotel
class Room {
  final String id;
  final String type;
  final double pricePerNight;
  final int capacity;
  final String description;
  final List<String> features;

  const Room({
    required this.id,
    required this.type,
    required this.pricePerNight,
    required this.capacity,
    required this.description,
    required this.features,
  });
}
