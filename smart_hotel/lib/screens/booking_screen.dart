import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/hotel.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import 'qr_screen.dart';

class BookingScreen extends StatefulWidget {
  final Hotel hotel;
  final Room room;
  const BookingScreen({super.key, required this.hotel, required this.room});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = BookingService();

  // Form controllers
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();

  // Dates
  DateTime? _checkIn;
  DateTime? _checkOut;

  // UI state
  int _currentStep = 0; // 0: Dates, 1: Guest Info, 2: Payment
  bool _isProcessing = false;
  String _selectedPayment = 'Credit Card';

  int get _nights => (_checkIn != null && _checkOut != null)
      ? _checkOut!.difference(_checkIn!).inDays
      : 0;

  double get _total => _nights * widget.room.pricePerNight;

  Future<void> _pickDate(bool isCheckIn) async {
    final now = DateTime.now();
    final first = isCheckIn ? now : (_checkIn ?? now).add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: first,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary, secondary: AppTheme.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          // Reset check-out if it's before new check-in
          if (_checkOut != null && !_checkOut!.isAfter(picked)) {
            _checkOut = null;
          }
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  Future<void> _simulatePayment() async {
    setState(() => _isProcessing = true);
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    final booking = _service.createBooking(
      hotel: widget.hotel,
      room: widget.room,
      checkIn: _checkIn!,
      checkOut: _checkOut!,
      guestName: _nameController.text.trim(),
      guestIdNumber: _idController.text.trim(),
      guestPhone: _phoneController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    // Navigate to QR screen, replacing booking flow
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => QRScreen(booking: booking)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Your Stay'),
        backgroundColor: AppTheme.primary,
      ),
      body: Column(children: [
        // Step indicator
        _StepIndicator(currentStep: _currentStep),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(children: [
                // ── Summary Card ─────────────────────────────────────────
                _SummaryCard(hotel: widget.hotel, room: widget.room, checkIn: _checkIn, checkOut: _checkOut, nights: _nights, total: _total),
                const SizedBox(height: 24),

                // ── Step 0: Date Selection ────────────────────────────────
                if (_currentStep == 0) ...[
                  const _SectionTitle(text: 'Select Your Dates'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _DateButton(
                      label: 'Check-in',
                      date: _checkIn,
                      icon: Icons.login_rounded,
                      onTap: () => _pickDate(true),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _DateButton(
                      label: 'Check-out',
                      date: _checkOut,
                      icon: Icons.logout_rounded,
                      onTap: () => _pickDate(false),
                    )),
                  ]),
                  if (_nights > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.nights_stay_rounded, color: AppTheme.accent),
                        const SizedBox(width: 10),
                        Text('$_nights night${_nights > 1 ? 's' : ''} · SAR ${_total.toInt()} total',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                      ]),
                    ),
                  ],
                ],

                // ── Step 1: Guest Information ─────────────────────────────
                if (_currentStep == 1) ...[
                  const _SectionTitle(text: 'Your Information'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _idController,
                    decoration: const InputDecoration(labelText: 'National ID / Iqama Number', prefixIcon: Icon(Icons.badge_outlined)),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.trim().isEmpty ?? true) return 'Please enter your ID number';
                      if (v!.trim().length < 8) return 'ID must be at least 8 digits';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v?.trim().isEmpty ?? true) return 'Please enter your phone number';
                      if (v!.trim().length < 9) return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                ],

                // ── Step 2: Payment ───────────────────────────────────────
                if (_currentStep == 2) ...[
                  const _SectionTitle(text: 'Payment Method'),
                  const SizedBox(height: 12),
                  ...['Credit Card', 'Apple Pay', 'Mada', 'Bank Transfer'].map((method) =>
                    GestureDetector(
                      onTap: () => setState(() => _selectedPayment = method),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedPayment == method ? AppTheme.accent : const Color(0xFFE5E7EB),
                            width: _selectedPayment == method ? 2 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Icon(_paymentIcon(method), color: _selectedPayment == method ? AppTheme.accent : AppTheme.textMuted),
                          const SizedBox(width: 12),
                          Text(method, style: TextStyle(fontWeight: FontWeight.w600,
                              color: _selectedPayment == method ? AppTheme.primary : AppTheme.textMuted)),
                          const Spacer(),
                          if (_selectedPayment == method) const Icon(Icons.check_circle_rounded, color: AppTheme.accent),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Order Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB))),
                    child: Column(children: [
                      _PriceRow(label: '${widget.room.type} × $_nights nights', value: 'SAR ${_total.toInt()}'),
                      const _PriceRow(label: 'Taxes & Fees (15%)', value: 'Included'),
                      const Divider(height: 20),
                      _PriceRow(label: 'Total', value: 'SAR ${_total.toInt()}', bold: true),
                    ]),
                  ),
                ],

                const SizedBox(height: 30),
              ]),
            ),
          ),
        ),

        // ── Navigation Buttons ─────────────────────────────────────────────
        _BottomBar(
          currentStep: _currentStep,
          isProcessing: _isProcessing,
          canAdvance: _canAdvance(),
          onBack: () => setState(() => _currentStep--),
          onNext: _onNext,
        ),
      ]),
    );
  }

  bool _canAdvance() {
    switch (_currentStep) {
      case 0: return _checkIn != null && _checkOut != null && _nights > 0;
      case 1: return true; // validated on submit
      case 2: return true;
      default: return false;
    }
  }

  void _onNext() {
    if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) return;
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _simulatePayment();
    }
  }

  IconData _paymentIcon(String method) {
    switch (method) {
      case 'Apple Pay': return Icons.apple;
      case 'Mada': return Icons.credit_card_rounded;
      case 'Bank Transfer': return Icons.account_balance_outlined;
      default: return Icons.credit_card;
    }
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const labels = ['Dates', 'Details', 'Payment'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(children: List.generate(3, (i) {
        final done = i < currentStep;
        final active = i == currentStep;
        return Expanded(child: Row(children: [
          if (i > 0) Expanded(child: Container(height: 2, color: done ? AppTheme.accent : const Color(0xFFE5E7EB))),
          Column(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: done || active ? AppTheme.accent : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
              ),
              child: Center(child: done
                  ? const Icon(Icons.check, size: 14, color: AppTheme.primary)
                  : Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: active ? AppTheme.primary : AppTheme.textMuted))),
            ),
            const SizedBox(height: 4),
            Text(labels[i], style: TextStyle(fontSize: 11, color: active ? AppTheme.primary : AppTheme.textMuted,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal)),
          ]),
          if (i < 2) const Expanded(child: SizedBox()),
        ]));
      })),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Hotel hotel;
  final Room room;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int nights;
  final double total;

  const _SummaryCard({required this.hotel, required this.room, required this.checkIn,
      required this.checkOut, required this.nights, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF0F3460)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Icon(Icons.hotel_rounded, color: AppTheme.accent, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(hotel.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          Text(room.type, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('SAR ${room.pricePerNight.toInt()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const Text('per night', style: TextStyle(color: Colors.white60, fontSize: 11)),
        ]),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});
  @override
  Widget build(BuildContext context) => Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark)));
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final IconData icon;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.date, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: date != null ? AppTheme.accent : const Color(0xFFE5E7EB), width: date != null ? 1.5 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 14, color: date != null ? AppTheme.accent : AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ]),
          const SizedBox(height: 6),
          Text(
            date != null ? '${date!.day}/${date!.month}/${date!.year}' : 'Select date',
            style: TextStyle(fontWeight: FontWeight.w700, color: date != null ? AppTheme.textDark : AppTheme.textMuted, fontSize: 14),
          ),
        ]),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _PriceRow({required this.label, required this.value, this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(label, style: TextStyle(color: bold ? AppTheme.textDark : AppTheme.textMuted, fontWeight: bold ? FontWeight.w700 : FontWeight.normal, fontSize: bold ? 15 : 13)),
      const Spacer(),
      Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 16 : 13, color: bold ? AppTheme.primary : AppTheme.textDark)),
    ]),
  );
}

class _BottomBar extends StatelessWidget {
  final int currentStep;
  final bool isProcessing;
  final bool canAdvance;
  final VoidCallback onBack;
  final VoidCallback onNext;
  const _BottomBar({required this.currentStep, required this.isProcessing,
      required this.canAdvance, required this.onBack, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Row(children: [
        if (currentStep > 0)
          OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Back', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        if (currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: canAdvance && !isProcessing ? onNext : null,
            child: isProcessing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                : Text(currentStep == 2 ? 'Confirm & Pay' : 'Continue'),
          ),
        ),
      ]),
    );
  }
}
