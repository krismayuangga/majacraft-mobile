import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';

class KYCScreen extends StatefulWidget {
  const KYCScreen({super.key});

  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nikController = TextEditingController();
  final _imagePicker = ImagePicker();
  final PageController _pageController = PageController();

  File? _ktpImage;
  File? _selfieImage;
  bool _isSubmitting = false;
  String? _errorMessage;
  int _currentStep = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _nikController.dispose();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, bool isKtp) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);

        // Validate file size (max 10MB)
        final fileSize = await file.length();
        final fileSizeMB = fileSize / (1024 * 1024);

        if (fileSizeMB > 10) {
          setState(() {
            _errorMessage =
                'Ukuran file terlalu besar (${fileSizeMB.toStringAsFixed(1)} MB).\nMaksimal 10MB.';
          });
          return;
        }

        // Validate file format (JPG/PNG only)
        final extension = image.path.toLowerCase().split('.').last;
        if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
          setState(() {
            _errorMessage =
                'Format file tidak didukung.\nGunakan JPG atau PNG.';
          });
          return;
        }

        setState(() {
          if (isKtp) {
            _ktpImage = file;
          } else {
            _selfieImage = file;
          }
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memilih gambar: $e';
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
    } else if (_currentStep == 1) {
      if (_ktpImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan ambil foto KTP terlebih dahulu'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _takeLiveSelfie() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo != null) {
        final file = File(photo.path);

        // Validate file size (max 10MB)
        final fileSize = await file.length();
        final fileSizeMB = fileSize / (1024 * 1024);

        if (fileSizeMB > 10) {
          setState(() {
            _errorMessage =
                'Ukuran foto terlalu besar (${fileSizeMB.toStringAsFixed(1)} MB).\nMaksimal 10MB. Coba ambil ulang dengan pencahayaan lebih rendah.';
          });
          return;
        }

        setState(() {
          _selfieImage = file;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengambil foto: $e';
      });
    }
  }

  Future<void> _submitKYC() async {
    if (_ktpImage == null || _selfieImage == null) {
      setState(() {
        _errorMessage = 'Silakan lengkapi semua dokumen';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/users/kyc'),
      );

      request.headers.addAll({'Authorization': 'Bearer $token'});

      request.fields['kycNik'] = _nikController.text;

      // Add files with explicit MIME type
      final ktpExtension = _ktpImage!.path.toLowerCase().split('.').last;
      final ktpMimeType = ktpExtension == 'png' ? 'image/png' : 'image/jpeg';

      final selfieExtension = _selfieImage!.path.toLowerCase().split('.').last;
      final selfieMimeType = selfieExtension == 'png'
          ? 'image/png'
          : 'image/jpeg';

      request.files.add(
        await http.MultipartFile.fromPath(
          'kycKtp',
          _ktpImage!.path,
          contentType: MediaType.parse(ktpMimeType),
        ),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'kycSelfie',
          _selfieImage!.path,
          contentType: MediaType.parse(selfieMimeType),
        ),
      );

      print('[KYC] Submitting to: ${ApiConfig.baseUrl}/api/users/kyc');
      print('[KYC] NIK: ${_nikController.text}');
      print('[KYC] KTP file: ${_ktpImage!.path}');
      print('[KYC] Selfie file: ${_selfieImage!.path}');

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final trimmedResponse = responseData.trim();

      print('[KYC] Response status: ${response.statusCode}');
      print('[KYC] Response length: ${responseData.length} bytes');
      print('[KYC] Response trimmed length: ${trimmedResponse.length} bytes');

      if (trimmedResponse.isNotEmpty && trimmedResponse.length < 500) {
        print('[KYC] Response body: $trimmedResponse');
      } else if (trimmedResponse.length >= 500) {
        print(
          '[KYC] Response body (first 200 chars): ${trimmedResponse.substring(0, 200)}...',
        );
      } else {
        print('[KYC] Response is empty or whitespace only');
      }

      // Check if response is empty or whitespace
      if (trimmedResponse.isEmpty) {
        if (response.statusCode == 404) {
          throw Exception(
            'Endpoint /api/users/kyc belum tersedia (404).\n\nBackend perlu membuat endpoint POST /api/users/kyc',
          );
        } else if (response.statusCode == 500) {
          throw Exception(
            'Server Error (500)\n\nBackend crash atau error tanpa response.\n\nCek server logs untuk detail.',
          );
        } else if (response.statusCode >= 200 && response.statusCode < 300) {
          // Success but empty body - might be intentional
          if (mounted) {
            await authProvider.refreshUserData();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(child: Text('Verifikasi KYC berhasil dikirim!')),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          return;
        } else {
          throw Exception(
            'Server response kosong (Status: ${response.statusCode})',
          );
        }
      }

      // Handle server errors (500) with response body
      if (response.statusCode == 500) {
        String errorDetail = '';
        try {
          final errorJson = jsonDecode(trimmedResponse);
          errorDetail = errorJson['error'] ?? errorJson['message'] ?? '';
        } catch (e) {
          // Response might be plain text or HTML
          if (trimmedResponse.length < 200) {
            errorDetail = trimmedResponse;
          } else {
            errorDetail = trimmedResponse.substring(0, 200);
          }
        }

        throw Exception(
          'Server Error (500)\n\nBackend error saat proses request.\n\n${errorDetail.isNotEmpty ? "Detail: $errorDetail" : "Response tidak ada detail error"}',
        );
      }

      // Try to parse JSON, handle parsing errors
      Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(trimmedResponse);
      } on FormatException catch (e) {
        print('[KYC] JSON Parse Error: $e');
        if (trimmedResponse.startsWith('<!DOCTYPE') ||
            trimmedResponse.startsWith('<html')) {
          throw Exception(
            'Endpoint /api/users/kyc belum tersedia.\n\nBackend mengembalikan HTML page, bukan JSON.\n\nEndpoint perlu menerima:\n- kycNik (string)\n- kycKtp (file)\n- kycSelfie (file)',
          );
        }
        throw Exception(
          'Response bukan JSON yang valid.\n\nFormat Error: ${e.message}\n\nResponse: ${trimmedResponse.substring(0, trimmedResponse.length > 100 ? 100 : trimmedResponse.length)}',
        );
      } catch (e) {
        throw Exception(
          'Error parsing response: ${e.toString()}\n\nResponse: ${trimmedResponse.substring(0, trimmedResponse.length > 100 ? 100 : trimmedResponse.length)}',
        );
      }

      print('[KYC] Parsed JSON: $jsonData');

      // Handle different status codes
      if (response.statusCode == 200 && jsonData['success'] == true) {
        if (mounted) {
          // Update user KYC status from response
          final kycStatus = jsonData['data']?['kycStatus'] ?? 'PENDING';
          await authProvider.updateKycStatus(kycStatus);

          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      jsonData['data']?['message'] ??
                          'Verifikasi KYC berhasil dikirim!',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else if (response.statusCode == 400) {
        // Bad Request - validation error
        final errorMsg =
            jsonData['error'] ?? jsonData['message'] ?? 'Request tidak valid';
        throw Exception('Validation Error\n\n$errorMsg');
      } else if (response.statusCode == 401) {
        // Unauthorized
        throw Exception(
          'Unauthorized\n\nSesi login Anda sudah expired. Silakan login ulang.',
        );
      } else if (response.statusCode == 403) {
        // Forbidden
        throw Exception(
          'Forbidden\n\nAnda tidak memiliki akses untuk fitur ini.',
        );
      } else {
        // Other errors
        final errorMsg =
            jsonData['error'] ??
            jsonData['message'] ??
            'Gagal mengirim verifikasi KYC';
        throw Exception('Error (${response.statusCode})\n\n$errorMsg');
      }
    } catch (e) {
      print('[KYC] Error: $e');
      setState(() {
        // Clean up error message - remove "Exception: " prefix
        String errorMsg = e.toString();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring('Exception: '.length);
        }
        _errorMessage = errorMsg;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header with Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF653611), const Color(0xFF8B5E3C)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // AppBar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verifikasi Identitas',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Lindungi akun Anda',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress Stepper
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
                    child: Row(
                      children: [
                        _buildStepIndicator(0, 'NIK'),
                        _buildStepLine(0),
                        _buildStepIndicator(1, 'KTP'),
                        _buildStepLine(1),
                        _buildStepIndicator(2, 'Selfie'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildNIKStep(),
                  _buildKTPStep(),
                  _buildSelfieStep(),
                ],
              ),
            ),

            // Bottom Navigation
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Kembali',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: _currentStep == 0 ? 1 : 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : (_currentStep == 2 ? _submitKYC : _nextStep),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF653611),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentStep == 2
                                        ? 'Kirim Verifikasi'
                                        : 'Lanjutkan',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _currentStep == 2
                                        ? Icons.check_circle_outline
                                        : Icons.arrow_forward,
                                    size: 20,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted || isActive
                ? Colors.white
                : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: isActive ? 3 : 2),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Color(0xFF653611), size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? const Color(0xFF653611) : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive || isCompleted ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = step < _currentStep;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.white : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildNIKStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Illustration Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF653611).withOpacity(0.1),
                    const Color(0xFF8B5E3C).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF653611).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF653611).withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      size: 48,
                      color: Color(0xFF653611),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Masukkan NIK Anda',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF653611),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'NIK akan digunakan untuk verifikasi identitas sesuai dengan KTP',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // NIK Input
            const Text(
              'Nomor Induk Kependudukan (NIK)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nikController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
              ],
              decoration: InputDecoration(
                hintText: '16 digit nomor KTP',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.normal,
                  letterSpacing: 0,
                ),
                prefixIcon: const Icon(
                  Icons.credit_card,
                  color: Color(0xFF653611),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF653611),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'NIK tidak boleh kosong';
                }
                if (value.length != 16) {
                  return 'NIK harus 16 digit';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Info Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'NIK Anda akan dijaga kerahasiaannya dan hanya digunakan untuk proses verifikasi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKTPStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF653611).withOpacity(0.1),
                  const Color(0xFF8B5E3C).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.credit_card,
                        color: Color(0xFF653611),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Foto KTP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF653611),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInstructionItem(
                  Icons.check_circle_outline,
                  'Pastikan seluruh bagian KTP terlihat jelas',
                ),
                _buildInstructionItem(
                  Icons.light_mode_outlined,
                  'Gunakan pencahayaan yang cukup',
                ),
                _buildInstructionItem(
                  Icons.photo_camera_outlined,
                  'Hindari refleksi cahaya pada KTP',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Photo Container
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _ktpImage == null
                  ? _buildPhotoPlaceholder(
                      icon: Icons.credit_card,
                      title: 'Ambil Foto KTP',
                      subtitle: 'Tekan tombol di bawah untuk mengambil foto',
                      onTap: () => _showImageSourceDialog(true),
                    )
                  : _buildPhotoPreview(
                      image: _ktpImage!,
                      onRetake: () => _showImageSourceDialog(true),
                      onDelete: () => setState(() => _ktpImage = null),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF653611).withOpacity(0.1),
                  const Color(0xFF8B5E3C).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.face_retouching_natural,
                        color: Color(0xFF653611),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Selfie dengan KTP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF653611),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInstructionItem(
                  Icons.account_circle_outlined,
                  'Posisikan wajah dan KTP dalam frame',
                ),
                _buildInstructionItem(
                  Icons.visibility_outlined,
                  'Pastikan wajah dan KTP terlihat jelas',
                ),
                _buildInstructionItem(
                  Icons.no_flash_outlined,
                  'Jangan gunakan filter atau edit foto',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Photo Container
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _selfieImage == null
                  ? _buildPhotoPlaceholder(
                      icon: Icons.face_retouching_natural,
                      title: 'Ambil Selfie dengan KTP',
                      subtitle: 'Gunakan kamera depan untuk selfie',
                      onTap: _takeLiveSelfie,
                    )
                  : _buildPhotoPreview(
                      image: _selfieImage!,
                      onRetake: _takeLiveSelfie,
                      onDelete: () => setState(() => _selfieImage = null),
                    ),
            ),
          ),

          // Error Message
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[900],
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage!.contains('Backend')) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[700],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Untuk sementara, data sudah tersimpan di device.',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF653611)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF653611).withOpacity(0.2),
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF653611).withOpacity(0.1),
                    const Color(0xFF8B5E3C).withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: const Color(0xFF653611)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF653611),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ambil Foto',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview({
    required File image,
    required VoidCallback onRetake,
    required VoidCallback onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.file(
              image,
              width: double.infinity,
              height: 280,
              fit: BoxFit.cover,
            ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),
            // Success Badge
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Foto Tersimpan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Action Buttons
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onRetake,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text(
                        'Ambil Ulang',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog(bool isKtp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isKtp ? 'Pilih Foto KTP' : 'Pilih Foto Selfie',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSourceButton(
                  icon: Icons.camera_alt,
                  title: 'Kamera',
                  subtitle: 'Ambil foto baru',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, isKtp);
                  },
                ),
                const SizedBox(height: 12),
                _buildSourceButton(
                  icon: Icons.photo_library,
                  title: 'Galeri',
                  subtitle: 'Pilih dari galeri',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery, isKtp);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF653611).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF653611), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
