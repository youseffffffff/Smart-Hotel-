import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../app_theme.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

/// Simulates scanning/verifying the QR code as a room key
class AccessScreen extends StatefulWidget {
  final Booking booking;
  const AccessScreen({super.key, required this.booking});

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

enum VerifyState { scanning, verifying, granted, denied }

class _AccessScreenState extends State<AccessScreen>
    with SingleTickerProviderStateMixin {
  // Verification states

  VerifyState _state = VerifyState.scanning;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  String _denyReason = '';
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.elasticOut));
    _animController.forward();

    // Auto-simulate scan after a short delay
    _scanTimer = Timer(const Duration(milliseconds: 800), _startVerification);
  }

  void _startVerification() {
    setState(() => _state = VerifyState.verifying);

    // Simulate backend verification delay
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      _animController.reset();
      _performVerification();
      _animController.forward();
    });
  }

  void _performVerification() {
    final booking = BookingService().findById(widget.booking.id);

    if (booking == null) {
      setState(() {
        _state = VerifyState.denied;
        _denyReason = 'Booking not found in system';
      });
      return;
    }

    if (booking.status == BookingStatus.cancelled) {
      setState(() {
        _state = VerifyState.denied;
        _denyReason = 'Booking has been cancelled';
      });
      return;
    }

    if (!booking.isQrValid) {
      setState(() {
        _state = VerifyState.denied;
        _denyReason = 'Digital key has expired';
      });
      return;
    }

    final now = DateTime.now();
    final checkInDate = DateTime(
        booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
    final today = DateTime(now.year, now.month, now.day);

    if (today.isBefore(checkInDate)) {
      setState(() {
        _state = VerifyState.denied;
        _denyReason =
            'Check-in date is in the future\n(${booking.checkIn.day}/${booking.checkIn.month}/${booking.checkIn.year})';
      });
      return;
    }

    if (today.isAfter(DateTime(
        booking.checkOut.year, booking.checkOut.month, booking.checkOut.day))) {
      setState(() {
        _state = VerifyState.denied;
        _denyReason = 'Check-out date has passed';
      });
      return;
    }

    // All checks passed!
    setState(() => _state = VerifyState.granted);
  }

  @override
  void dispose() {
    _animController.dispose();
    _scanTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: _headerColor),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text('Room Access',
                    style: TextStyle(
                        color: _headerColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(width: 48),
            ]),
          ),

          Expanded(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case VerifyState.scanning:
        return _ScanningView(booking: widget.booking);
      case VerifyState.verifying:
        return _VerifyingView();
      case VerifyState.granted:
        return _GrantedView(
            booking: widget.booking, onBack: () => Navigator.pop(context));
      case VerifyState.denied:
        return _DeniedView(
            reason: _denyReason,
            onRetry: _retry,
            onBack: () => Navigator.pop(context));
    }
  }

  void _retry() {
    _animController.reset();
    setState(() => _state = VerifyState.scanning);
    _animController.forward();
    _scanTimer = Timer(const Duration(milliseconds: 500), _startVerification);
  }

  Color get _bgColor {
    switch (_state) {
      case VerifyState.granted:
        return const Color(0xFF064E3B);
      case VerifyState.denied:
        return const Color(0xFF7F1D1D);
      default:
        return AppTheme.primary;
    }
  }

  Color get _headerColor {
    return _state == VerifyState.granted || _state == VerifyState.denied
        ? Colors.white
        : Colors.white;
  }
}

// ── Sub-views ─────────────────────────────────────────────────────────────────

class _ScanningView extends StatefulWidget {
  final Booking booking;
  const _ScanningView({required this.booking});

  @override
  State<_ScanningView> createState() => _ScanningViewState();
}

class _ScanningViewState extends State<_ScanningView>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanAnim;
  late Animation<double> _scanPos;

  @override
  void initState() {
    super.initState();
    _scanAnim =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _scanPos = Tween<double>(begin: 0, end: 200).animate(_scanAnim);
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Present Your Key',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Room ${widget.booking.roomNumber}',
            style: const TextStyle(color: AppTheme.accent, fontSize: 16)),
        const SizedBox(height: 32),

        // QR with scan line
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 30)
            ],
          ),
          child: Stack(clipBehavior: Clip.hardEdge, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: QrImageView(
                data:
                    '${widget.booking.id}|${widget.booking.checkIn.millisecondsSinceEpoch}|${widget.booking.qrExpiresAt.millisecondsSinceEpoch}',
                version: QrVersions.auto,
                size: 240,
                eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square, color: AppTheme.primary),
                dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppTheme.primary),
              ),
            ),
            // Animated scan line
            AnimatedBuilder(
              animation: _scanPos,
              builder: (_, __) => Positioned(
                top: _scanPos.value + 8,
                left: 8,
                right: 8,
                child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.8),
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.accent.withOpacity(0.6),
                              blurRadius: 8)
                        ])),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 24),
        const Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white54)),
          SizedBox(width: 10),
          Text('Initializing scan…',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
        ]),
      ]),
    );
  }
}

class _VerifyingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.accent,
              strokeCap: StrokeCap.round)),
      SizedBox(height: 24),
      Text('Verifying Access',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
      SizedBox(height: 8),
      Text('Checking booking details…',
          style: TextStyle(color: Colors.white54, fontSize: 14)),
    ]);
  }
}

class _GrantedView extends StatelessWidget {
  final Booking booking;
  final VoidCallback onBack;
  const _GrantedView({required this.booking, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.success, width: 3),
          ),
          child: const Icon(Icons.lock_open_rounded,
              size: 52, color: AppTheme.success),
        ),
        const SizedBox(height: 24),
        const Text('ACCESS GRANTED',
            style: TextStyle(
                color: AppTheme.success,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 2)),
        const SizedBox(height: 8),
        Text('Welcome, ${booking.guestName.split(' ').first}!',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),

        // Room details
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.success.withOpacity(0.4)),
          ),
          child: Column(children: [
            _AccessRow(
                icon: Icons.hotel_rounded,
                label: 'Room',
                value: booking.roomNumber),
            _AccessRow(
                icon: Icons.door_sliding_rounded,
                label: 'Type',
                value: booking.roomType),
            _AccessRow(
                icon: Icons.logout_rounded,
                label: 'Check-out',
                value:
                    '${booking.checkOut.day}/${booking.checkOut.month}/${booking.checkOut.year}'),
          ]),
        ),

        const SizedBox(height: 32),
        const Text('Door is unlocking…',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 6),
        const LinearProgressIndicator(
            backgroundColor: Colors.white24,
            color: AppTheme.success,
            minHeight: 4),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Done',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ]),
    );
  }
}

class _DeniedView extends StatelessWidget {
  final String reason;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  const _DeniedView(
      {required this.reason, required this.onRetry, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.danger.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.danger, width: 3),
          ),
          child:
              const Icon(Icons.lock_rounded, size: 52, color: AppTheme.danger),
        ),
        const SizedBox(height: 24),
        const Text('ACCESS DENIED',
            style: TextStyle(
                color: AppTheme.danger,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 2)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.danger.withOpacity(0.4)),
          ),
          child: Text(reason,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onBack,
          child: const Text('Go Back', style: TextStyle(color: Colors.white60)),
        ),
      ]),
    );
  }
}

class _AccessRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _AccessRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 16, color: AppTheme.success),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ]),
      );
}
