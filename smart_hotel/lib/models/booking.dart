// Booking status enum //3
enum BookingStatus { active, expired, cancelled }

// Booking model representing a hotel reservation
class Booking {
  final String id;
  final String hotelId;
  final String hotelName;
  final String roomId;
  final String roomType;
  final String roomNumber;
  final DateTime checkIn;
  final DateTime checkOut;
  final String guestName;
  final String guestIdNumber;
  final String guestPhone;
  final double totalPrice;
  final DateTime createdAt;
  final DateTime qrExpiresAt; // QR code expiry (24h after check-in)
  BookingStatus status;

  Booking({
    required this.id,
    required this.hotelId,
    required this.hotelName,
    required this.roomId,
    required this.roomType,
    required this.roomNumber,
    required this.checkIn,
    required this.checkOut,
    required this.guestName,
    required this.guestIdNumber,
    required this.guestPhone,
    required this.totalPrice,
    required this.createdAt,
    required this.qrExpiresAt,
    this.status = BookingStatus.active,
  });

  // Check if QR is still valid
  bool get isQrValid =>
      status == BookingStatus.active && DateTime.now().isBefore(qrExpiresAt);

  // Get remaining seconds until QR expiry
  int get secondsUntilExpiry {
    final remaining = qrExpiresAt.difference(DateTime.now());
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  // Number of nights
  int get nights => checkOut.difference(checkIn).inDays;
}
