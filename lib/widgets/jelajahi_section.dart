import 'dart:async';
import 'package:flutter/material.dart';

class JelajahiSection extends StatefulWidget {
  final void Function(String route) onNavigate;
  const JelajahiSection({super.key, required this.onNavigate});

  @override
  State<JelajahiSection> createState() => _JelajahiSectionState();
}

class _JelajahiSectionState extends State<JelajahiSection> {
  final _controller = PageController();
  int _current = 0;
  Timer? _timer;

  static const _cards = [
    _CardData(
      route: 'studio',
      eyebrow: 'UNTUK SENIMAN',
      title: 'Buka Studio',
      description: 'Daftarkan karya Anda dan jangkau kolektor di seluruh Nusantara.',
      icon: Icons.storefront_outlined,
      bgColors: [Color(0xFF2D1F0A), Color(0xFF1E1608)],
      accentColor: Color(0xFFB45309),
      iconColor: Color(0xFFFBBF24),
    ),
    _CardData(
      route: 'ruang-budaya',
      eyebrow: 'INSPIRASI & CERITA',
      title: 'Ruang Budaya',
      description: 'Artikel, kisah di balik karya, dan acara budaya Nusantara.',
      icon: Icons.menu_book_outlined,
      bgColors: [Color(0xFF1A1208), Color(0xFF120F06)],
      accentColor: Color(0xFF854D0E),
      iconColor: Color(0xFFFACC15),
    ),
    _CardData(
      route: 'verifikasi',
      eyebrow: 'KEASLIAN TERJAMIN',
      title: 'Galeri Sertifikat',
      description: 'Verifikasi keaslian karya yang tercatat permanen di blockchain BSC.',
      icon: Icons.verified_outlined,
      bgColors: [Color(0xFF0C1410), Color(0xFF0A110D)],
      accentColor: Color(0xFF065F46),
      iconColor: Color(0xFF34D399),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted) return;
      final next = (_current + 1) % _cards.length;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Jelajahi MajaCraft',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              width: 56, height: 3,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFB45309)]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ]),
        ),
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _controller,
            itemCount: _cards.length,
            onPageChanged: (i) { setState(() => _current = i); _startTimer(); },
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ShortcutCard(data: _cards[i], onTap: () => widget.onNavigate(_cards[i].route)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_cards.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _current == i ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _current == i ? const Color(0xFFB45309) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          )),
        ),
      ]),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final _CardData data;
  final VoidCallback onTap;
  const _ShortcutCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: data.bgColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Stack(children: [
          // Dekoratif blur circle
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.accentColor.withOpacity(0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: data.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(data.icon, color: data.iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(data.eyebrow,
                      style: TextStyle(color: data.iconColor, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  Text(data.title,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                ]),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.4), size: 14),
              ]),
              const SizedBox(height: 10),
              Text(data.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12, height: 1.4)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _CardData {
  final String route, eyebrow, title, description;
  final IconData icon;
  final List<Color> bgColors;
  final Color accentColor, iconColor;
  const _CardData({
    required this.route, required this.eyebrow, required this.title,
    required this.description, required this.icon, required this.bgColors,
    required this.accentColor, required this.iconColor,
  });
}