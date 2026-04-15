import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../app_theme.dart';
import '../models/booking.dart';
import 'access_screen.dart';

class QRScreen extends StatefulWidget {
  final Booking booking;
  const QRScreen({super.key, required this.booking});

  @override
  State<QRScreen> createState() => _QRScreenState();
}

class _QRScreenState extends State<QRScreen> with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _secondsLeft = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.booking.secondsUntilExpiry;

    // Pulse animation for active QR
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft = widget.booking.secondsUntilExpiry;
        if (_secondsLeft == 0) {
          widget.booking.status = BookingStatus.expired;
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // Format seconds as HH:MM:SS
  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // Determine color based on remaining time
  Color get _timerColor {
    if (_secondsLeft > 3600) return AppTheme.success; // > 1 hour
    if (_secondsLeft > 600) return Colors.orange; // > 10 min
    return AppTheme.danger; // < 10 min
  }

  bool get _isExpired => !widget.booking.isQrValid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text('Your Digital Key'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            // ── Success Banner ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.success.withOpacity(0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
                const SizedBox(width: 8),
                Text('Booking Confirmed! #${widget.booking.id}',
                    style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),

            const SizedBox(height: 24),

            // ── QR Code Card ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: Column(children: [
                // Hotel & Room Info
                Text(widget.booking.hotelName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('Room ${widget.booking.roomNumber} · ${widget.booking.roomType}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                const SizedBox(height: 20),

                // QR Code
                if (_isExpired)
                  Container(
                    width: 220, height: 220,
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.lock_rounded, size: 56, color: Color(0xFF9CA3AF)),
                      const SizedBox(height: 12),
                      const Text('QR Expired', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700)),
                    ]),
                  )
                else
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (_, child) => Transform.scale(scale: _pulseAnimation.value, child: child),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 20)],
                      ),
                      child: QrImageView(
                        data: '${widget.booking.id}|${widget.booking.checkIn.millisecondsSinceEpoch}|${widget.booking.qrExpiresAt.millisecondsSinceEpoch}',
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.primary),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.primary),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Booking ID
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF8F6F0), borderRadius: BorderRadius.circular(8)),
                  child: Text('ID: ${widget.booking.id}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark, letterSpacing: 2)),
                ),

                const SizedBox(height: 20),

                // Countdown Timer
                if (!_isExpired) ...[
                  const Text('Key expires in', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _timerColor, fontFeatures: const []),
                    child: Text(_formatTime(_secondsLeft)),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _secondsLeft / (48 * 3600),
                      backgroundColor: const Color(0xFFE5E7EB),
                      color: _timerColor,
                      minHeight: 6,
                    ),
                  ),
                ] else ...[
                  const Text('This key has expired', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700)),
                ],
              ]),
            ),

            const SizedBox(height: 20),

            // ── Booking Details Card ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Column(children: [
                _DetailRow(icon: Icons.person_rounded, label: 'Guest', value: widget.booking.guestName),
                _DetailRow(icon: Icons.login_rounded, label: 'Check-in', value: _formatDate(widget.booking.checkIn)),
                _DetailRow(icon: Icons.logout_rounded, label: 'Check-out', value: _formatDate(widget.booking.checkOut)),
                _DetailRow(icon: Icons.nights_stay_rounded, label: 'Duration', value: '${widget.booking.nights} night${widget.booking.nights > 1 ? 's' : ''}'),
                _DetailRow(icon: Icons.payments_rounded, label: 'Total Paid', value: 'SAR ${widget.booking.totalPrice.toInt()}', isLast: true),
              ]),
            ),

            const SizedBox(height: 24),

            // ── Use as Key Button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExpired ? null : () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AccessScreen(booking: widget.booking))),
                icon: Icon(_isExpired ? Icons.lock_rounded : Icons.key_rounded, size: 20),
                label: Text(_isExpired ? 'Key Expired' : 'Use as Room Key'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isExpired ? Colors.grey : AppTheme.accent,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Back to home
            TextButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text('Back to Home', style: TextStyle(color: Colors.white60)),
            ),
          ]),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day} ${_month(d.month)} ${d.year}';
  String _month(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  const _DetailRow({required this.icon, required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: isLast ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
      child: Row(children: [
        Icon(icon, size: 16, color: AppTheme.accent),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
  }
}
