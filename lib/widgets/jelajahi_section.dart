import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  static const _items = [
    ('studio', 'https://majacraft.id/images/buka-studio.png'),
    ('ruang-budaya', 'https://majacraft.id/images/ruang-budaya.png'),
    ('verifikasi', 'https://majacraft.id/images/galeri-sertifikat.png'),
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
      _controller.animateToPage(
        (_current + 1) % _items.length,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _controller,
            itemCount: _items.length,
            onPageChanged: (i) {
              setState(() => _current = i);
              _startTimer();
            },
            itemBuilder: (context, i) {
              final (route, imageUrl) = _items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => widget.onNavigate(route),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      memCacheWidth: 800,
                      placeholder: (_, __) => Container(color: Colors.grey.shade100),
                      errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_items.length, (i) => AnimatedContainer(
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