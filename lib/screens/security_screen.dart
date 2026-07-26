import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'change_password_screen.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Check if user logged in via Google
    final isGoogleLogin = user?.email.contains('gmail') ?? false; // Simplified detection

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF653611)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Keamanan & Password',
          style: TextStyle(
            color: Color(0xFF653611),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Google Login Warning (if applicable)
            if (isGoogleLogin)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Login via Google',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Jika Anda masuk menggunakan Google, tidak perlu mengganti password. Password hanya diperlukan untuk login dengan email.',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Security Options
            _buildSectionHeader('KEAMANAN AKUN'),
            _buildMenuCard([
              _SecurityMenuItem(
                icon: Icons.lock_reset,
                title: 'Ubah Password',
                subtitle: 'Ganti password untuk keamanan akun',
                iconColor: const Color(0xFF653611),
                enabled: !isGoogleLogin,
                onTap: !isGoogleLogin
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      }
                    : null,
              ),
              _SecurityMenuItem(
                icon: Icons.fingerprint,
                title: 'Biometric Login',
                subtitle: 'Login dengan sidik jari atau Face ID',
                iconColor: Colors.green,
                badge: 'SEGERA',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur biometric akan segera hadir'),
                      backgroundColor: Color(0xFF653611),
                    ),
                  );
                },
              ),
            ]),

            // Privacy Options
            _buildSectionHeader('PRIVASI'),
            _buildMenuCard([
              _SecurityMenuItem(
                icon: Icons.visibility_off_outlined,
                title: 'Aktivitas Login',
                subtitle: 'Lihat riwayat login ke akun Anda',
                iconColor: Colors.blue,
                badge: 'SEGERA',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur aktivitas login akan segera hadir'),
                      backgroundColor: Color(0xFF653611),
                    ),
                  );
                },
              ),
              _SecurityMenuItem(
                icon: Icons.devices_outlined,
                title: 'Perangkat Terhubung',
                subtitle: 'Kelola perangkat yang terhubung',
                iconColor: Colors.purple,
                badge: 'SEGERA',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur perangkat akan segera hadir'),
                      backgroundColor: Color(0xFF653611),
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<_SecurityMenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              ListTile(
                enabled: item.enabled,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.enabled
                        ? item.iconColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.enabled ? item.iconColor : Colors.grey,
                    size: 22,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: item.enabled ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                    if (item.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.badge!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: item.subtitle != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: item.enabled ? Colors.grey[600] : Colors.grey,
                          ),
                        ),
                      )
                    : null,
                trailing: item.enabled
                    ? Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      )
                    : null,
                onTap: item.enabled ? item.onTap : null,
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 72,
                  color: Colors.grey[200],
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SecurityMenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final String? badge;
  final bool enabled;
  final VoidCallback? onTap;

  _SecurityMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.iconColor,
    this.badge,
    this.enabled = true,
    this.onTap,
  });
}
