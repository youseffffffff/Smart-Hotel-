import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/hotel.dart';
import '../services/booking_service.dart';
import 'hotel_details_screen.dart';
import 'my_bookings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = BookingService();
  final _searchController = TextEditingController();
  String _query = '';
  double _maxPrice = 5000;

  List<Hotel> get _filtered => _service.hotels.where((h) {
        final matchesQuery =
            h.name.toLowerCase().contains(_query.toLowerCase()) ||
                h.location.toLowerCase().contains(_query.toLowerCase());
        final matchesPrice = h.rooms.any((r) => r.pricePerNight <= _maxPrice);
        return matchesQuery && matchesPrice;
      }).toList();

  void _showFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter Hotels',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark)),
                const SizedBox(height: 20),
                Row(children: [
                  const Text('Max price / night:',
                      style: TextStyle(color: AppTheme.textMuted)),
                  const Spacer(),
                  Text('SAR ${_maxPrice.toInt()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accent,
                          fontSize: 16)),
                ]),
                Slider(
                  value: _maxPrice,
                  min: 200,
                  max: 5000,
                  divisions: 48,
                  activeColor: AppTheme.accent,
                  onChanged: (v) => setLocal(() => _maxPrice = v),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.primary,
            actions: [
              IconButton(
                icon:
                    const Icon(Icons.bookmark_rounded, color: AppTheme.accent),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MyBookingsScreen())),
                tooltip: 'My Bookings',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primary, Color(0xFF0F3460)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Good ${_greeting()},',
                              style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 14,
                                  letterSpacing: 1)),
                          const Text('Find Your Stay',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5)),
                        ]),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ]),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(
                        hintText: 'Search hotels or cities…',
                        prefixIcon:
                            Icon(Icons.search, color: AppTheme.textMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  IconButton(
                      onPressed: _showFilter,
                      icon: const Icon(Icons.tune_rounded,
                          color: AppTheme.accent)),
                ]),
              ),
            ),
          ),

          // ── Results Header ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text('${_filtered.length} hotels available',
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            ),
          ),

          // ── Hotel Cards ───────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: _filtered.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(children: [
                          Icon(Icons.search_off_rounded,
                              size: 56, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          const Text('No hotels found',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 16)),
                        ]),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _HotelCard(hotel: _filtered[i]),
                      childCount: _filtered.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ── Individual Hotel Card Widget ─────────────────────────────────────────────
class _HotelCard extends StatelessWidget {
  final Hotel hotel;
  const _HotelCard({required this.hotel});

  @override
  Widget build(BuildContext context) {
    final minPrice =
        hotel.rooms.map((r) => r.pricePerNight).reduce((a, b) => a < b ? a : b);

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => HotelDetailsScreen(hotel: hotel))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Stack(children: [
              Image.network(hotel.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(Icons.hotel,
                          size: 48, color: Color(0xFF9CA3AF)))),
              // Rating badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text(hotel.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary)),
                  ]),
                ),
              ),
            ]),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hotel.name,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 2),
                Expanded(
                    child: Text(hotel.location,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textMuted),
                        overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                // Amenity chips
                ...hotel.amenities.take(3).map((a) => Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF3F0E8),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(a,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textDark)),
                    )),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('From SAR ${minPrice.toInt()}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary)),
                  const Text('/ night',
                      style:
                          TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ]),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
