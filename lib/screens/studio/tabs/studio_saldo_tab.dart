import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/balance.dart';
import '../../../models/store.dart';
import '../../../services/api_service.dart';
import '../../../providers/auth_provider.dart';

class StudioSaldoTab extends StatefulWidget {
  const StudioSaldoTab({Key? key}) : super(key: key);

  @override
  State<StudioSaldoTab> createState() => _StudioSaldoTabState();
}

class _StudioSaldoTabState extends State<StudioSaldoTab> {
  final ApiService _apiService = ApiService();
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Balance? _balance;
  Store? _store;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) throw Exception('Token tidak ditemukan');

      final balanceResponse = await _apiService.get(
        '/api/studio/balance',
        token: token,
      );

      if (balanceResponse['success'] == true) {
        _balance = Balance.fromJson(balanceResponse['data']);
      }

      final storeResponse = await _apiService.get(
        '/api/studio/store',
        token: token,
      );

      if (storeResponse['success'] == true) {
        _store = Store.fromJson(storeResponse['data']);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading balance: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final balance = _balance;
    final store = _store;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final needsVerification =
                    authProvider.user != null &&
                    authProvider.user!.kycStatus != 'VERIFIED';
                if (!needsVerification) return const SizedBox.shrink();
                return Column(
                  children: [
                    _buildVerificationBanner(),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
            _buildHeroBalanceCard(balance),
            const SizedBox(height: 20),
            _buildRekeningInfo(store),
            const SizedBox(height: 20),
            _buildActionButtons(balance, store),
            const SizedBox(height: 8),
            _buildMinimalInfo(),
            const SizedBox(height: 24),
            if (balance?.withdrawals.isNotEmpty == true) ...[
              _buildHistoryHeader(),
              const SizedBox(height: 10),
              ...balance!.withdrawals.map((w) => _buildWithdrawalCard(w)),
            ] else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFBBF24), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFB45309),
            size: 18,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Toko Belum Terverifikasi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // Navigate back to main app to access Profile/KYC page
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Silakan lengkapi verifikasi KYC di menu AKUN'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Verifikasi →',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBalanceCard(Balance? balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'SALDO TERSEDIA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currencyFormat.format(balance?.availableBalance ?? 0),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'siap dicairkan',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 12),
          _buildInlineRow(
            'Pendapatan Kotor',
            _currencyFormat.format(balance?.grossRevenue ?? 0),
            Colors.white.withOpacity(0.9),
          ),
          const SizedBox(height: 6),
          _buildInlineRow(
            'Fee Platform (${balance?.feePercent ?? 0}%)',
            '- ${_currencyFormat.format(balance?.feeAmount ?? 0)}',
            Colors.white.withOpacity(0.9),
          ),
          const SizedBox(height: 6),
          _buildInlineRow(
            'Sudah Dicairkan',
            '- ${_currencyFormat.format(balance?.totalWithdrawn ?? 0)}',
            Colors.white.withOpacity(0.9),
          ),
        ],
      ),
    );
  }

  Widget _buildRekeningInfo(Store? store) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance,
                size: 18,
                color: Color(0xFFB45309),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'REKENING PENCAIRAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ubah',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward,
                      size: 12,
                      color: Color(0xFFB45309),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (store?.bankName != null && store?.bankAccount != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    size: 14,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${store!.bankName} - ${store.bankAccount}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'a.n. ${store.bankHolder ?? '-'}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rekening belum diset. Set di tab Pengaturan',
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(Balance? balance, Store? store) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _canWithdraw(balance, store) ? () {} : null,
            icon: const Icon(Icons.account_balance_wallet, size: 18),
            label: const Text('Cairkan Dana'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB45309),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[500],
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.lock_outline, size: 16),
            label: const Text('PIN', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFB45309), width: 1.5),
              foregroundColor: const Color(0xFFB45309),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalInfo() {
    return Center(
      child: Text(
        'Minimal pencairan Rp 50.000',
        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Riwayat Pencairan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Lihat Semua',
            style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada riwayat pencairan',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineRow(String label, String value, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: textColor)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWithdrawalCard(Withdrawal withdrawal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currencyFormat.format(withdrawal.netAmount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: withdrawal.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  withdrawal.statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: withdrawal.statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${withdrawal.bankName} - ${withdrawal.bankAccount}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd MMM yyyy, HH:mm').format(withdrawal.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          if (withdrawal.fee > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Fee: ${_currencyFormat.format(withdrawal.fee)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  bool _canWithdraw(Balance? balance, Store? store) {
    if (balance == null || store == null) return false;
    if (balance.availableBalance < 50000) return false;
    if (store.bankName == null || store.bankAccount == null) return false;
    return true;
  }
}
