import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../models/hotel.dart';
import 'booking_screen.dart';

class HotelDetailsScreen extends StatefulWidget {
  final Hotel hotel;
  const HotelDetailsScreen({super.key, required this.hotel});

  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedRoomIndex = 0;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Entrance animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));

    // Track scroll for parallax
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _animController.forward());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    final selectedRoom = hotel.rooms[_selectedRoomIndex];
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EE),
      body: Stack(
        children: [
          // ── Main Scrollable Content ──────────────────────────────────
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Cinematic Hero ────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                stretch: true,
                backgroundColor: AppTheme.primary,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _GlassButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _GlassButton(
                      icon: Icons.favorite_border_rounded,
                      onTap: () {},
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                    child: _GlassButton(
                      icon: Icons.ios_share_rounded,
                      onTap: () {},
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Hotel image with parallax
                      Transform.translate(
                        offset: Offset(0, _scrollOffset * 0.4),
                        child: Image.network(
                          hotel.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.primary,
                            child: const Icon(Icons.hotel,
                                size: 64, color: Colors.white24),
                          ),
                        ),
                      ),
                      // Multi-stop gradient overlay
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.3, 0.65, 1.0],
                            colors: [
                              Colors.black.withOpacity(0.35),
                              Colors.transparent,
                              Colors.black.withOpacity(0.25),
                              Colors.black.withOpacity(0.78),
                            ],
                          ),
                        ),
                      ),
                      // Bottom text overlay on hero
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stars
                            Row(children: [
                              ...List.generate(
                                  5,
                                  (i) => Icon(
                                        i < hotel.rating.floor()
                                            ? Icons.star_rounded
                                            : (i < hotel.rating
                                                ? Icons.star_half_rounded
                                                : Icons.star_border_rounded),
                                        size: 15,
                                        color: AppTheme.accent,
                                      )),
                              const SizedBox(width: 6),
                              Text(
                                '${hotel.rating} · Exceptional',
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            Text(
                              hotel.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 13, color: AppTheme.accent),
                              const SizedBox(width: 4),
                              Text(
                                hotel.location,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Body ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Quick Stats Card ──────────────────────────
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(children: [
                            _StatChip(
                                icon: Icons.king_bed_rounded,
                                label: '${hotel.rooms.length} Room Types'),
                            _VertDivider(),
                            _StatChip(
                                icon: Icons.wifi_rounded, label: 'Free WiFi'),
                            _VertDivider(),
                            _StatChip(
                                icon: Icons.star_rounded,
                                label: '${hotel.rating} / 5.0'),
                          ]),
                        ),

                        // ── About ─────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionHeader(text: 'About'),
                              const SizedBox(height: 10),
                              Text(
                                hotel.description,
                                style: const TextStyle(
                                  color: Color(0xFF5A5A6E),
                                  fontSize: 14,
                                  height: 1.75,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Amenities Grid ────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionHeader(text: 'Amenities'),
                              const SizedBox(height: 14),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 3.6,
                                children: hotel.amenities
                                    .map((a) => _AmenityTile(label: a))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),

                        // ── Rooms ─────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                          child: const _SectionHeader(text: 'Choose Your Room'),
                        ),

                        // Horizontal scroll room cards
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            scrollDirection: Axis.horizontal,
                            itemCount: hotel.rooms.length,
                            itemBuilder: (_, i) => _RoomCard(
                              room: hotel.rooms[i],
                              isSelected: i == _selectedRoomIndex,
                              onTap: () =>
                                  setState(() => _selectedRoomIndex = i),
                              cardWidth: screenWidth * 0.70,
                            ),
                          ),
                        ),

                        // ── Room Feature Chips ────────────────────────
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                      begin: const Offset(0, 0.05),
                                      end: Offset.zero)
                                  .animate(anim),
                              child: child,
                            ),
                          ),
                          child: _SelectedRoomDetail(
                            key: ValueKey(_selectedRoomIndex),
                            room: selectedRoom,
                          ),
                        ),

                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Fixed Bottom Book Bar ──────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BookBar(
              room: selectedRoom,
              onBook: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      BookingScreen(hotel: widget.hotel, room: selectedRoom),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Horizontal Room Card ──────────────────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final Room room;
  final bool isSelected;
  final VoidCallback onTap;
  final double cardWidth;

  const _RoomCard({
    required this.room,
    required this.isSelected,
    required this.onTap,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: cardWidth,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.accent : const Color(0xFFE8E5DE),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primary.withOpacity(0.28)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 22 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Room type header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accent.withOpacity(0.15)
                      : const Color(0xFFF3F0E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.king_bed_rounded,
                  size: 18,
                  color: isSelected ? AppTheme.accent : AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  room.type,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isSelected ? Colors.white : AppTheme.textDark,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: AppTheme.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      size: 12, color: AppTheme.primary),
                ),
            ]),
            // Description
            Text(
              room.description,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white60 : AppTheme.textMuted,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Capacity + Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.people_outline_rounded,
                      size: 14,
                      color: isSelected ? Colors.white54 : AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${room.capacity} guests',
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            isSelected ? Colors.white54 : AppTheme.textMuted),
                  ),
                ]),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: 'SAR ${room.pricePerNight.toInt()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? AppTheme.accent : AppTheme.primary,
                      ),
                    ),
                    TextSpan(
                      text: '/night',
                      style: TextStyle(
                          fontSize: 11,
                          color:
                              isSelected ? Colors.white38 : AppTheme.textMuted),
                    ),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Room Features Chip List ───────────────────────────────────────────────────
class _SelectedRoomDetail extends StatelessWidget {
  final Room room;
  const _SelectedRoomDetail({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E5DE)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.checklist_rounded, size: 15, color: AppTheme.accent),
          const SizedBox(width: 6),
          Text(
            '${room.type} · What\'s included',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark),
          ),
        ]),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: room.features
              .map((f) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3EE),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                            color: AppTheme.accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        f,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w500),
                      ),
                    ]),
                  ))
              .toList(),
        ),
      ]),
    );
  }
}

// ── Sticky Bottom Bar ─────────────────────────────────────────────────────────
class _BookBar extends StatelessWidget {
  final Room room;
  final VoidCallback onBook;
  const _BookBar({required this.room, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Price per night',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'SAR ${room.pricePerNight.toInt()}',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary),
              ),
              const TextSpan(
                text: ' /night',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ]),
          ),
        ]),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withOpacity(0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: onBook,
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: const Text('Book Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              elevation: 0,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Micro Widgets ─────────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.32),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
            letterSpacing: -0.3,
          ),
        ),
      ]);
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Icon(icon, size: 20, color: AppTheme.accent),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ]),
      );
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: const Color(0xFFE8E5DE));
}

class _AmenityTile extends StatelessWidget {
  final String label;
  const _AmenityTile({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8E5DE)),
        ),
        child: Row(children: [
          Icon(_icon(label), size: 14, color: AppTheme.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      );

  IconData _icon(String a) {
    const map = {
      'WiFi': Icons.wifi_rounded,
      'Pool': Icons.pool_rounded,
      'Spa': Icons.spa_rounded,
      'Gym': Icons.fitness_center_rounded,
      'Parking': Icons.local_parking_rounded,
      'Concierge': Icons.room_service_rounded,
      'Beach': Icons.beach_access_rounded,
      'Bar': Icons.local_bar_rounded,
      'Dining': Icons.restaurant_rounded,
      'Tours': Icons.map_rounded,
      'Shuttle': Icons.airport_shuttle_rounded,
      'Business': Icons.business_center_rounded,
    };
    for (final key in map.keys) {
      if (a.contains(key)) return map[key]!;
    }
    return Icons.check_circle_outline_rounded;
  }
}
