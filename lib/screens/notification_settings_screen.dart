import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _orderUpdates = true;
  bool _chatMessages = true;
  bool _promoEnabled = false;
  bool _disputeUpdates = true;
  bool _systemAnnouncements = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('notif_push') ?? true;
      _orderUpdates = prefs.getBool('notif_order') ?? true;
      _chatMessages = prefs.getBool('notif_chat') ?? true;
      _promoEnabled = prefs.getBool('notif_promo') ?? false;
      _disputeUpdates = prefs.getBool('notif_dispute') ?? true;
      _systemAnnouncements = prefs.getBool('notif_system') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1A14),
        foregroundColor: const Color(0xFFFBBF24),
        title: const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(
            color: Color(0xFFFBBF24),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Master toggle
          _buildSectionHeader('Notifikasi Utama'),
          _buildToggle(
            title: 'Push Notification',
            subtitle: 'Aktifkan semua notifikasi dari MajaCraft',
            value: _pushEnabled,
            icon: Icons.notifications_outlined,
            onChanged: (v) {
              setState(() => _pushEnabled = v);
              _savePreference('notif_push', v);
            },
            isMain: true,
          ),

          if (_pushEnabled) ...[
            const Divider(height: 1, indent: 16),
            _buildSectionHeader('Jenis Notifikasi'),
            _buildToggle(
              title: 'Update Pesanan',
              subtitle: 'Status pesanan, pengiriman, konfirmasi',
              value: _orderUpdates,
              icon: Icons.shopping_bag_outlined,
              onChanged: (v) {
                setState(() => _orderUpdates = v);
                _savePreference('notif_order', v);
              },
            ),
            _buildToggle(
              title: 'Pesan & Chat',
              subtitle: 'Pesan baru dari penjual atau admin',
              value: _chatMessages,
              icon: Icons.chat_bubble_outline,
              onChanged: (v) {
                setState(() => _chatMessages = v);
                _savePreference('notif_chat', v);
              },
            ),
            _buildToggle(
              title: 'Komplain & Dispute',
              subtitle: 'Update status komplain pesanan',
              value: _disputeUpdates,
              icon: Icons.gavel_outlined,
              onChanged: (v) {
                setState(() => _disputeUpdates = v);
                _savePreference('notif_dispute', v);
              },
            ),
            _buildToggle(
              title: 'Pengumuman Sistem',
              subtitle: 'Info maintenance, kebijakan baru',
              value: _systemAnnouncements,
              icon: Icons.campaign_outlined,
              onChanged: (v) {
                setState(() => _systemAnnouncements = v);
                _savePreference('notif_system', v);
              },
            ),
            _buildToggle(
              title: 'Promo & Penawaran',
              subtitle: 'Flash sale, diskon, dan promo terbaru',
              value: _promoEnabled,
              icon: Icons.local_offer_outlined,
              onChanged: (v) {
                setState(() => _promoEnabled = v);
                _savePreference('notif_promo', v);
              },
            ),
          ],

          const SizedBox(height: 16),
          _buildSectionHeader('Informasi'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pengaturan ini mengontrol notifikasi in-app. '
                    'Untuk push notification dari perangkat, '
                    'atur melalui Pengaturan → Aplikasi → MajaCraft.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
    bool isMain = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: isMain ? 15 : 14,
            fontWeight: isMain ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        secondary: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF653611).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF653611)),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF653611),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
