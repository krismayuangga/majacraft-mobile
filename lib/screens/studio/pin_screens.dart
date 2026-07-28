import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE PIN PAD WIDGET — Banking app style
// ─────────────────────────────────────────────────────────────────────────────
class PinPad extends StatelessWidget {
  final String value; // current digits
  final int length; // 6 for PIN, 6 for OTP
  final ValueChanged<String> onChanged;
  final String title;
  final String? subtitle;
  final Widget? extraAction; // e.g. "Lupa PIN?" button
  final Color accentColor;

  const PinPad({
    super.key,
    required this.value,
    this.length = 6,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.extraAction,
    this.accentColor = const Color(0xFFB45309),
  });

  void _press(String digit) {
    HapticFeedback.lightImpact();
    if (value.length < length) {
      onChanged(value + digit);
    }
  }

  void _delete() {
    HapticFeedback.lightImpact();
    if (value.isNotEmpty) {
      onChanged(value.substring(0, value.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 32),

        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(length, (i) {
            final filled = i < value.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: filled ? 16 : 14,
              height: filled ? 16 : 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? accentColor : Colors.transparent,
                border: Border.all(
                  color: filled ? accentColor : const Color(0xFFAAAAAA),
                  width: 2,
                ),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),

        const SizedBox(height: 40),

        // Number Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              _buildRow(['1', '2', '3']),
              const SizedBox(height: 12),
              _buildRow(['4', '5', '6']),
              const SizedBox(height: 12),
              _buildRow(['7', '8', '9']),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Extra action (e.g., Lupa PIN?) or empty
                  SizedBox(width: 80, height: 64, child: extraAction),
                  _numButton('0'),
                  // Backspace
                  SizedBox(
                    width: 80,
                    height: 64,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(40),
                        onTap: _delete,
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          onChanged('');
                        },
                        child: const Center(
                          child: Icon(
                            Icons.backspace_outlined,
                            size: 24,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_numButton).toList(),
    );
  }

  Widget _numButton(String digit) {
    return SizedBox(
      width: 80,
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          splashColor: accentColor.withOpacity(0.15),
          highlightColor: accentColor.withOpacity(0.08),
          onTap: () => _press(digit),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SET PIN FLOW — OTP → PIN → Confirm PIN
// Opens as full-screen route
// ─────────────────────────────────────────────────────────────────────────────
class SetPinScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  const SetPinScreen({super.key, this.onSuccess});

  static Future<void> show(BuildContext context, {VoidCallback? onSuccess}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SetPinScreen(onSuccess: onSuccess),
      ),
    );
  }

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  int _step = 0; // 0=send OTP, 1=enter OTP, 2=enter PIN, 3=confirm PIN
  final _otpTextController = TextEditingController();
  String _otp = '';
  String _pin = '';
  String _pinConfirm = '';
  bool _isLoading = false;
  String? _error;

  static const _amber = Color(0xFFB45309);

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _step = 0;
    });
    try {
      final token = context.read<AuthProvider>().token;
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/otp/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'type': 'pin_reset'}),
      );
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode == 200 && data['success'] == true) {
        setState(() => _step = 1);
      } else {
        setState(
          () =>
              _error = data['error'] ?? data['message'] ?? 'Gagal mengirim OTP',
        );
      }
    } catch (e) {
      setState(() => _error = 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitPin() async {
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
        body: jsonEncode({'otp': _otp, 'pin': _pin}),
      );
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (resp.statusCode == 200 && data['success'] == true) {
        Navigator.pop(context);
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN berhasil diset! ✓'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _error = data['error'] ?? data['message'] ?? 'Gagal set PIN';
          _step = 1; // kembali ke OTP jika error
          _otp = '';
          _pin = '';
          _pinConfirm = '';
        });
      }
    } catch (e) {
      setState(() => _error = 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _stepTitle {
    switch (_step) {
      case 0:
        return 'Mengirim Kode OTP...';
      case 1:
        return 'Masukkan Kode OTP';
      case 2:
        return 'Buat PIN Baru';
      case 3:
        return 'Konfirmasi PIN';
      default:
        return '';
    }
  }

  String? get _stepSubtitle {
    switch (_step) {
      case 1:
        return 'Kode 6 digit telah dikirim ke email Anda';
      case 2:
        return 'PIN 6 digit untuk konfirmasi setiap pencairan dana';
      case 3:
        return 'Masukkan ulang PIN untuk konfirmasi';
      default:
        return null;
    }
  }

  void _handlePinChange(String v) {
    setState(() {
      _pin = v;
      _error = null;
    });
    if (v.length == 6) {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _step = 3);
      });
    }
  }

  void _handleConfirmChange(String v) {
    setState(() {
      _pinConfirm = v;
      _error = null;
    });
    if (v.length == 6) {
      HapticFeedback.mediumImpact();
      if (v == _pin) {
        Future.delayed(const Duration(milliseconds: 200), _submitPin);
      } else {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _pinConfirm = '';
              _error = 'PIN tidak cocok, coba lagi';
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Set PIN Pencairan',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading && _step == 0
            ? const Center(child: CircularProgressIndicator(color: _amber))
            : Column(
                children: [
                  // Step indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Row(
                      children: List.generate(3, (i) {
                        final active = i < (_step == 0 ? 0 : _step);
                        final current = i == (_step - 1).clamp(0, 2);
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 3,
                            decoration: BoxDecoration(
                              color: active || current
                                  ? _amber
                                  : const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_step == 1)
                            TextButton(
                              onPressed: _isLoading ? null : _sendOtp,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              child: const Text(
                                'Kirim ulang',
                                style: TextStyle(fontSize: 11, color: _amber),
                              ),
                            ),
                        ],
                      ),
                    ),

                  Expanded(
                    child: _step == 1
                        // ── Step 1: OTP via text form biasa ──────────────
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 32),
                                const Icon(
                                  Icons.email_outlined,
                                  size: 56,
                                  color: _amber,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Masukkan Kode OTP',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Kode 6 digit telah dikirim ke email Anda',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF666666),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                TextField(
                                  controller: _otpTextController,
                                  autofocus: true,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 6,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    letterSpacing: 12,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '000000',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFCCCCCC),
                                      letterSpacing: 12,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8F8F8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFDDDDDD),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: _amber,
                                        width: 2,
                                      ),
                                    ),
                                    counterText: '',
                                  ),
                                  onChanged: (v) {
                                    setState(() {
                                      _otp = v;
                                      _error = null;
                                    });
                                  },
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            _otp = _otpTextController.text
                                                .trim();
                                            if (_otp.length != 6) {
                                              setState(
                                                () => _error =
                                                    'Kode OTP harus 6 digit',
                                              );
                                              return;
                                            }
                                            setState(() {
                                              _step = 2;
                                              _error = null;
                                            });
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _amber,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Lanjut',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: _isLoading ? null : _sendOtp,
                                  icon: const Icon(
                                    Icons.refresh,
                                    size: 16,
                                    color: _amber,
                                  ),
                                  label: const Text(
                                    'Kirim ulang kode',
                                    style: TextStyle(color: _amber),
                                  ),
                                ),
                              ],
                            ),
                          )
                        // ── Step 2 & 3: PIN via numpad banking ────────────
                        : PinPad(
                            value: _step == 2 ? _pin : _pinConfirm,
                            length: 6,
                            onChanged: _step == 2
                                ? _handlePinChange
                                : _handleConfirmChange,
                            title: _stepTitle,
                            subtitle: _stepSubtitle,
                            accentColor: _amber,
                          ),
                  ),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: _amber),
                    )
                  else
                    const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VERIFY PIN SCREEN — Enter PIN to confirm withdrawal
// ─────────────────────────────────────────────────────────────────────────────
class VerifyPinScreen extends StatefulWidget {
  final Future<bool> Function(String pin) onVerify;
  final String title;
  final String? subtitle;

  const VerifyPinScreen({
    super.key,
    required this.onVerify,
    this.title = 'Masukkan PIN',
    this.subtitle,
  });

  static Future<bool> show(
    BuildContext context, {
    required Future<bool> Function(String pin) onVerify,
    String title = 'Masukkan PIN',
    String? subtitle,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VerifyPinScreen(
          onVerify: onVerify,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
    return result == true;
  }

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  String _pin = '';
  bool _isLoading = false;
  String? _error;
  int _attempts = 0;

  static const _amber = Color(0xFFB45309);

  Future<void> _submit(String pin) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final ok = await widget.onVerify(pin);
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
      } else {
        _attempts++;
        setState(() {
          _pin = '';
          _error = 'PIN salah (${_attempts}x). Coba lagi.';
        });
      }
    } catch (e) {
      setState(() {
        _pin = '';
        _error = 'Gagal: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleChange(String v) {
    setState(() {
      _pin = v;
      _error = null;
    });
    if (v.length == 6) {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 200), () => _submit(v));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black54),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _amber),
                    )
                  : PinPad(
                      value: _pin,
                      length: 6,
                      onChanged: _handleChange,
                      title: widget.title,
                      subtitle: widget.subtitle,
                      accentColor: _amber,
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
