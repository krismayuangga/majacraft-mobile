import 'package:flutter/material.dart';
import 'tabs/studio_ringkasan_tab.dart';
import 'tabs/studio_karya_tab.dart';
import 'tabs/studio_pesanan_tab.dart';
import 'tabs/studio_saldo_tab.dart';
import 'tabs/studio_pengaturan_tab.dart';
import 'add_product_screen.dart';

class StudioScreen extends StatefulWidget {
  final int initialTab;

  const StudioScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1A14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Studio Seniman',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
              },
              icon: const Icon(Icons.add, size: 16, color: Color(0xFF1C1A14)),
              label: const Text(
                'Tambah Karya',
                style: TextStyle(
                  color: Color(0xFF1C1A14),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFD4A020),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            color: const Color(0xFF1C1A14),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              indicatorColor: const Color(0xFFFBBF24),
              indicatorWeight: 3,
              labelColor: const Color(0xFFFBBF24),
              unselectedLabelColor: const Color(0xFFB45309),
              labelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.dashboard, size: 24),
                  text: 'Home',
                  iconMargin: EdgeInsets.only(bottom: 2),
                ),
                Tab(
                  icon: Icon(Icons.inventory_2, size: 24),
                  text: 'Karya',
                  iconMargin: EdgeInsets.only(bottom: 2),
                ),
                Tab(
                  icon: Icon(Icons.shopping_bag, size: 24),
                  text: 'Pesanan',
                  iconMargin: EdgeInsets.only(bottom: 2),
                ),
                Tab(
                  icon: Icon(Icons.account_balance_wallet, size: 24),
                  text: 'Saldo',
                  iconMargin: EdgeInsets.only(bottom: 2),
                ),
                Tab(
                  icon: Icon(Icons.settings, size: 24),
                  text: 'Setting',
                  iconMargin: EdgeInsets.only(bottom: 2),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StudioRingkasanTab(onGoToPesanan: () => _tabController.animateTo(2)),
          const StudioKaryaTab(),
          const StudioPesananTab(),
          const StudioSaldoTab(),
          const StudioPengaturanTab(),
        ],
      ),
    );
  }
}
