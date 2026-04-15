import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import 'qr_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final _service = BookingService();

  @override
  Widget build(BuildContext context) {
    final bookings = _service.allBookings;

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings'), backgroundColor: AppTheme.primary),
      backgroundColor: const Color(0xFFFAF9F6),
      body: bookings.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.hotel_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No bookings yet', style: TextStyle(fontSize: 17, color: AppTheme.textMuted)),
                const SizedBox(height: 8),
                const Text('Book a hotel to see it here', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (_, i) => _BookingCard(
                booking: bookings[i],
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QRScreen(booking: bookings[i]))),
              ),
            ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;
  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = booking.isQrValid;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(children: [
          // Top: hotel + status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primary : const Color(0xFF6B7280),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.hotel_rounded, color: AppTheme.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(booking.hotelName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                Text('Room ${booking.roomNumber} · ${booking.roomType}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.success : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isActive ? Icons.radio_button_checked : Icons.cancel_outlined, size: 10, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(isActive ? 'Active' : 'Expired', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
          ),
          // Bottom: details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Check-in', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                Text('${booking.checkIn.day}/${booking.checkIn.month}/${booking.checkIn.year}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark)),
              ])),
              Container(width: 1, height: 30, color: const Color(0xFFE5E7EB)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                const Text('Duration', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                Text('${booking.nights}N', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark)),
              ])),
              Container(width: 1, height: 30, color: const Color(0xFFE5E7EB)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Total', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                Text('SAR ${booking.totalPrice.toInt()}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
              ])),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
            ]),
          ),
        ]),
      ),
    );
  }
}
