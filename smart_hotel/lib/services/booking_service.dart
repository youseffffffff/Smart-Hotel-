import 'package:uuid/uuid.dart';
import '../models/hotel.dart';
import '../models/booking.dart';

// BookingService handles all booking logic and data
class BookingService {
  // Singleton instance
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final _uuid = const Uuid();

  // In-memory booking storage
  final List<Booking> _bookings = [];

  // ─── Sample Hotel Data ───────────────────────────────────────────────────

  final List<Hotel> hotels = [
    Hotel(
      id: 'h1',
      name: 'Roshn Grand Riyadh',
      imageUrl:
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
      description:
          'Experience unrivalled luxury in the heart of Riyadh. Our 5-star property features panoramic city views, world-class dining, and a rejuvenating spa — perfect for business and leisure travellers alike.',
      location: 'King Fahd Road, Riyadh',
      rating: 4.8,
      amenities: [
        'Free WiFi',
        'Pool',
        'Spa',
        'Gym',
        'Valet Parking',
        'Concierge'
      ],
      rooms: [
        Room(
          id: 'r1a',
          type: 'Deluxe Room',
          pricePerNight: 650,
          capacity: 2,
          description: 'Elegant room with city view and king-size bed.',
          features: ['King Bed', 'City View', '55" TV', 'Minibar'],
        ),
        Room(
          id: 'r1b',
          type: 'Executive Suite',
          pricePerNight: 1200,
          capacity: 3,
          description:
              'Spacious suite with separate living area and butler service.',
          features: ['King Bed', 'Living Room', 'Butler Service', 'Jacuzzi'],
        ),
      ],
    ),
    Hotel(
      id: 'h2',
      name: 'AlUla Desert Retreat',
      imageUrl:
          'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800',
      description:
          'Nestled among ancient sandstone formations, this boutique retreat blends Nabataean heritage with contemporary comfort. Wake up to golden sunrise over the desert and star-gaze from your private terrace.',
      location: 'Old Town, AlUla',
      rating: 4.9,
      amenities: [
        'Desert Tours',
        'Private Pool',
        'Fine Dining',
        'Stargazing Deck'
      ],
      rooms: [
        Room(
          id: 'r2a',
          type: 'Desert Villa',
          pricePerNight: 1800,
          capacity: 2,
          description:
              'Stand-alone villa with private plunge pool and panoramic desert views.',
          features: ['Private Pool', 'Terrace', 'Outdoor Shower', 'Fire Pit'],
        ),
        Room(
          id: 'r2b',
          type: 'Cliff Suite',
          pricePerNight: 2400,
          capacity: 4,
          description: 'Dramatic suite carved into the sandstone cliff face.',
          features: [
            'Rock Walls',
            'Infinity View',
            '2 Bedrooms',
            'Chef Service'
          ],
        ),
      ],
    ),
    Hotel(
      id: 'h3',
      name: 'Jeddah Corniche Pearl',
      imageUrl:
          'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800',
      description:
          'Steps from the Red Sea, this contemporary hotel combines vibrant coastal energy with refined hospitality. Enjoy fresh seafood, water sports, and direct beach access from your room.',
      location: 'Corniche Road, Jeddah',
      rating: 4.6,
      amenities: [
        'Private Beach',
        'Water Sports',
        'Rooftop Bar',
        'Infinity Pool'
      ],
      rooms: [
        Room(
          id: 'r3a',
          type: 'Sea View Room',
          pricePerNight: 480,
          capacity: 2,
          description: 'Bright modern room with stunning Red Sea panoramas.',
          features: ['Sea View', 'Balcony', 'Queen Bed', 'Beach Access'],
        ),
        Room(
          id: 'r3b',
          type: 'Penthouse',
          pricePerNight: 3200,
          capacity: 6,
          description: 'Entire top floor with 360° sea and city views.',
          features: ['360° View', 'Private Pool', '3 Bedrooms', 'Home Theatre'],
        ),
      ],
    ),
    Hotel(
      id: 'h4',
      name: 'Tabuk Heritage Stay',
      imageUrl:
          'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800',
      description:
          'A curated boutique experience in the gateway to NEOM. Modern rooms, warm Arabian hospitality, and easy access to Tabuk\'s historic sites and outdoor adventures.',
      location: 'City Centre, Tabuk',
      rating: 4.4,
      amenities: ['Free WiFi', 'Airport Shuttle', 'Gym', 'Business Centre'],
      rooms: [
        Room(
          id: 'r4a',
          type: 'Standard Double',
          pricePerNight: 280,
          capacity: 2,
          description:
              'Comfortable room ideal for short stays and business travel.',
          features: ['Double Bed', 'Work Desk', 'Smart TV', 'Coffee Maker'],
        ),
        Room(
          id: 'r4b',
          type: 'Family Suite',
          pricePerNight: 520,
          capacity: 5,
          description:
              'Spacious suite with bunk beds and a kitchenette for families.',
          features: ['2 Bedrooms', 'Kitchenette', 'Bunk Beds', 'Sofa Bed'],
        ),
      ],
    ),
  ];

  // ─── CRUD Methods ────────────────────────────────────────────────────────

  /// Create a new booking and return it
  Booking createBooking({
    required Hotel hotel,
    required Room room,
    required DateTime checkIn,
    required DateTime checkOut,
    required String guestName,
    required String guestIdNumber,
    required String guestPhone,
  }) {
    final nights = checkOut.difference(checkIn).inDays;
    final bookingId = _uuid.v4().substring(0, 8).toUpperCase();
    final hotelNumber = int.tryParse(hotel.id.substring(1)) ?? 0;
    final roomSuffix = room.id.substring(2).toLowerCase();
    final roomIndex = int.tryParse(roomSuffix) ??
        (roomSuffix.isNotEmpty ? roomSuffix.codeUnitAt(0) - 96 : 0);
    final roomNumber = '${(hotelNumber * 100) + roomIndex}';

    final booking = Booking(
      id: bookingId,
      hotelId: hotel.id,
      hotelName: hotel.name,
      roomId: room.id,
      roomType: room.type,
      roomNumber: roomNumber,
      checkIn: checkIn,
      checkOut: checkOut,
      guestName: guestName,
      guestIdNumber: guestIdNumber,
      guestPhone: guestPhone,
      totalPrice: room.pricePerNight * nights,
      createdAt: DateTime.now(),
      // QR is valid for 48 hours from check-in date
      qrExpiresAt: checkIn.add(const Duration(hours: 48)),
    );

    _bookings.add(booking);
    _updateExpiredBookings();
    return booking;
  }

  /// Get all bookings (updates expired status first)
  List<Booking> get allBookings {
    _updateExpiredBookings();
    return List.unmodifiable(_bookings.reversed.toList());
  }

  /// Find booking by ID (used for QR verification)
  Booking? findById(String id) {
    _updateExpiredBookings();
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Mark expired bookings automatically
  void _updateExpiredBookings() {
    for (final b in _bookings) {
      if (b.status == BookingStatus.active &&
          DateTime.now().isAfter(b.qrExpiresAt)) {
        b.status = BookingStatus.expired;
      }
    }
  }

  /// Get hotel by ID
  Hotel? hotelById(String id) {
    try {
      return hotels.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }
}
