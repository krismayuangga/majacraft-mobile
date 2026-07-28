import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';

// ─── Set PIN Dialog ─────────────────────────────────────────────────────────
// Alur: Kirim OTP ke email → Masukkan OTP + PIN 6 digit baru
class SetPinDialog extends StatefulWidget {
  final VoidCallback? onSuccess;
  const SetPinDialog({super.key, this.onSuccess});

  @override
  State<SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<SetPinDialog> {
  final _otpController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinConfirmController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  bool _obscurePin = true;
  String? _error;

  static const _amber = Color(0xFFB45309);

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _pinController.dispose();
    _pinConfirmController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = context.read<AuthProvider>().token;
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/otp/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'type': 'PIN_SETUP'}),
      );
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode == 200 && data['success'] == true) {
        setState(() {
          _otpSent = true;
        });
      } else {
        setState(
          () =>
              _error = data['error'] ?? data['message'] ?? 'Gagal mengirim OTP',
        );
      }
    } catch (e) {
      setState(() => _error = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setPin() async {
    final otp = _otpController.text.trim();
    final pin = _pinController.text.trim();
    final pinConfirm = _pinConfirmController.text.trim();

    if (otp.length < 4) {
      setState(() => _error = 'Masukkan kode OTP dari email');
      return;
    }
    if (pin.length != 6) {
      setState(() => _error = 'PIN harus 6 digit');
      return;
    }
    if (pin != pinConfirm) {
      setState(() => _error = 'PIN tidak cocok');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = context.read<AuthProvider>().token;
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/pin/set'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'otp': otp, 'pin': pin}),
      );
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (resp.statusCode == 200 && data['success'] == true) {
        Navigator.pop(context);
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN berhasil diset!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(
          () => _error = data['error'] ?? data['message'] ?? 'Gagal set PIN',
        );
      }
    } catch (e) {
      setState(() => _error = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set PIN Pencairan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'PIN 6 digit untuk konfirmasi pencairan dana',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      content: _isLoading && !_otpSent
          ? const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // OTP Info
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: _amber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _otpSent
                                ? 'Kode OTP telah dikirim ke email Anda'
                                : 'Mengirim OTP ke email...',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (_otpSent)
                          TextButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: const Text(
                              'Kirim ulang',
                              style: TextStyle(fontSize: 11, color: _amber),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // OTP Input
                  const Text(
                    'KODE OTP *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _amber,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 8,
                    decoration: InputDecoration(
                      hintText: 'Masukkan kode dari email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PIN Input
                  const Text(
                    'PIN BARU (6 Digit) *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _amber,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    obscureText: _obscurePin,
                    decoration: InputDecoration(
                      hintText: '6 digit angka',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      counterText: '',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePin
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePin = !_obscurePin),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Confirm PIN
                  const Text(
                    'KONFIRMASI PIN *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _amber,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _pinConfirmController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    obscureText: _obscurePin,
                    decoration: InputDecoration(
                      hintText: 'Ulangi PIN',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      counterText: '',
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.red[700], fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        if (_otpSent)
          ElevatedButton(
            onPressed: _isLoading ? null : _setPin,
            style: ElevatedButton.styleFrom(
              backgroundColor: _amber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Set PIN', style: TextStyle(color: Colors.white)),
          ),
      ],
    );
  }
}

// ─── Withdraw Dialog ─────────────────────────────────────────────────────────
// Form pencairan dana dengan konfirmasi PIN
class WithdrawDialog extends StatefulWidget {
  final double availableBalance;
  final String? bankName;
  final String? bankAccount;
  final String? bankHolder;
  final VoidCallback onSuccess;

  const WithdrawDialog({
    super.key,
    required this.availableBalance,
    this.bankName,
    this.bankAccount,
    this.bankHolder,
    required this.onSuccess,
  });

  @override
  State<WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<WithdrawDialog> {
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePin = true;
  String? _error;

  static const _amber = Color(0xFFB45309);
  static final _fmt = RegExp(r'\B(?=(\d{3})+(?!\d))');

  @override
  void dispose() {
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountStr = _amountController.text
        .replaceAll('.', '')
        .replaceAll('Rp ', '')
        .trim();
    final amount = double.tryParse(amountStr) ?? 0;
    final pin = _pinController.text.trim();

    if (amount < 50000) {
      setState(() => _error = 'Minimal pencairan Rp 50.000');
      return;
    }
    if (amount > widget.availableBalance) {
      setState(() => _error = 'Nominal melebihi saldo tersedia');
      return;
    }
    if (pin.length != 6) {
      setState(() => _error = 'Masukkan PIN 6 digit');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = context.read<AuthProvider>().token;
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/studio/balance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount.toInt(),
          'bankName': widget.bankName,
          'bankAccount': widget.bankAccount,
          'bankHolder': widget.bankHolder,
          'pin': pin,
        }),
      );
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (resp.statusCode == 200 && data['success'] == true) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan pencairan berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final msg =
            data['error'] ?? data['message'] ?? 'Gagal mengajukan pencairan';
        // Jika PIN salah/belum set
        final isPinError = (msg as String).toLowerCase().contains('pin');
        setState(
          () => _error = isPinError
              ? 'PIN salah atau belum diset. Silakan set PIN dulu.'
              : msg,
        );
      }
    } catch (e) {
      setState(() => _error = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cairkan Dana',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Saldo tersedia: Rp ${widget.availableBalance.toStringAsFixed(0).replaceAllMapped(_fmt, (m) => '${m[0]}.')}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: _amber,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rekening tujuan
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, size: 16, color: _amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.bankName} - ${widget.bankAccount}\na.n. ${widget.bankHolder}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Nominal
            const Text(
              'JUMLAH PENCAIRAN *',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _amber,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Nominal dalam Rupiah',
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // PIN
            const Text(
              'PIN PENCAIRAN *',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _amber,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              obscureText: _obscurePin,
              decoration: InputDecoration(
                hintText: '6 digit PIN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                counterText: '',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePin
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: Colors.red[700], fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _amber,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Cairkan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
