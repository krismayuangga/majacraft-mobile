import 'package:flutter/material.dart';

class StudioStatistikTab extends StatefulWidget {
  const StudioStatistikTab({Key? key}) : super(key: key);

  @override
  State<StudioStatistikTab> createState() => _StudioStatistikTabState();
}

class _StudioStatistikTabState extends State<StudioStatistikTab> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Statistik',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analitik dan statistik toko Anda',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '🚧 Coming Soon',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
