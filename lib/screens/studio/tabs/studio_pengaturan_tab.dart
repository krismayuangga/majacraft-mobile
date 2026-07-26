import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/store.dart';
import '../../../models/region.dart';
import '../../../services/api_service.dart';
import '../../../services/upload_service.dart';
import '../../../services/region_service.dart';
import '../../../services/postal_code_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/bank_list.dart';
import 'dart:io';

class StudioPengaturanTab extends StatefulWidget {
  const StudioPengaturanTab({Key? key}) : super(key: key);

  @override
  State<StudioPengaturanTab> createState() => _StudioPengaturanTabState();
}

class _StudioPengaturanTabState extends State<StudioPengaturanTab>
    with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  final UploadService _uploadService = UploadService();
  final RegionService _regionService = RegionService();
  final PostalCodeService _postalCodeService = PostalCodeService();
  final _formKey = GlobalKey<FormState>();

  static const String baseUrl = 'https://majacraft.id';

  // Static cache to avoid redundant API calls
  static List<Province>? _cachedProvinces;
  static Store? _cachedStore;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  // Info Toko Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();

  // Bank Controllers
  final _bankAccountController = TextEditingController();
  final _bankHolderController = TextEditingController();
  final _bankOtpController = TextEditingController();

  Store? _store;
  bool _isLoading = true;
  bool _isSavingInfo = false;
  bool _isUploadingLogo = false;
  File? _logoFile;
  String? _uploadedLogoUrl;

  // Region dropdowns
  List<Province> _provinces = [];
  List<Regency> _regencies = [];
  List<District> _districts = [];
  List<Village> _villages = [];

  Province? _selectedProvince;
  Regency? _selectedRegency;
  District? _selectedDistrict;
  Village? _selectedVillage;

  bool _loadingProvinces = false;
  bool _loadingRegencies = false;
  bool _loadingDistricts = false;
  bool _loadingVillages = false;

  // Bank form state
  String? _selectedBank;
  String? _selectedBankCode;
  bool _showBankForm = false;
  bool _otpSentForBank = false;
  bool _isSavingBank = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Load provinces first, then store data to avoid race condition
  Future<void> _initializeData() async {
    await _loadProvinces();
    await _loadStoreData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _bankAccountController.dispose();
    _bankHolderController.dispose();
    _bankOtpController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    setState(() => _isLoading = true);

    try {
      // Use cache if available and fresh
      if (_cachedStore != null &&
          _cacheTime != null &&
          DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        _store = _cachedStore;
        await _populateForm();
        setState(() => _isLoading = false);
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await _apiService.get('/api/studio/store', token: token);

      if (response['success'] == true) {
        _store = Store.fromJson(response['data']);
        _cachedStore = _store; // Cache the result
        _cacheTime = DateTime.now();
        await _populateForm();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('[StudioPengaturan] Error loading store: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _populateForm() async {
    if (_store == null) return;

    _nameController.text = _store!.name ?? '';
    _descriptionController.text = _store!.description ?? '';
    _addressController.text = _store!.address ?? '';
    _postalCodeController.text = _store!.postalCode ?? '';
    _phoneController.text = _store!.phone ?? '';
    _bankAccountController.text = _store!.bankAccount ?? '';
    _bankHolderController.text = _store!.bankHolder ?? '';

    _selectedBank = _store!.bankName;

    // Restore region selections from store data
    if (_store!.province != null && _provinces.isNotEmpty) {
      _selectedProvince = _provinces.firstWhere(
        (p) => p.name == _store!.province,
        orElse: () => _provinces.first,
      );

      if (_selectedProvince != null) {
        await _loadRegencies(_selectedProvince!.id);

        if (_store!.city != null && _regencies.isNotEmpty) {
          _selectedRegency = _regencies.firstWhere(
            (r) => r.name == _store!.city,
            orElse: () => _regencies.first,
          );

          if (_selectedRegency != null) {
            await _loadDistricts(_selectedRegency!.id);

            if (_store!.district != null && _districts.isNotEmpty) {
              _selectedDistrict = _districts.firstWhere(
                (d) => d.name == _store!.district,
                orElse: () => _districts.first,
              );

              if (_selectedDistrict != null) {
                await _loadVillages(_selectedDistrict!.id);

                if (_store!.village != null && _villages.isNotEmpty) {
                  _selectedVillage = _villages.firstWhere(
                    (v) => v.name == _store!.village,
                    orElse: () => _villages.first,
                  );
                }
              }
            }
          }
        }
      }
    }
  }

  // ========== REGION LOADING ==========
  Future<void> _loadProvinces() async {
    // Use cache if available
    if (_cachedProvinces != null && _cachedProvinces!.isNotEmpty) {
      setState(() {
        _provinces = _cachedProvinces!;
        _loadingProvinces = false;
      });
      return;
    }

    setState(() => _loadingProvinces = true);
    try {
      final provinces = await _regionService.getProvinces();
      _cachedProvinces = provinces; // Cache the result
      setState(() {
        _provinces = provinces;
        _loadingProvinces = false;
      });
    } catch (e) {
      setState(() => _loadingProvinces = false);
      print('[StudioPengaturan] Error loading provinces: $e');
    }
  }

  Future<void> _loadRegencies(String provinceId) async {
    setState(() {
      _loadingRegencies = true;
      _regencies = [];
      _selectedRegency = null;
      _districts = [];
      _selectedDistrict = null;
      _villages = [];
      _selectedVillage = null;
    });

    try {
      final regencies = await _regionService.getRegencies(provinceId);
      setState(() {
        _regencies = regencies;
        _loadingRegencies = false;
      });
    } catch (e) {
      setState(() => _loadingRegencies = false);
      print('[StudioPengaturan] Error loading regencies: $e');
    }
  }

  Future<void> _loadDistricts(String regencyId) async {
    setState(() {
      _loadingDistricts = true;
      _districts = [];
      _selectedDistrict = null;
      _villages = [];
      _selectedVillage = null;
    });

    try {
      final districts = await _regionService.getDistricts(regencyId);
      setState(() {
        _districts = districts;
        _loadingDistricts = false;
      });
    } catch (e) {
      setState(() => _loadingDistricts = false);
      print('[StudioPengaturan] Error loading districts: $e');
    }
  }

  Future<void> _loadVillages(String districtId) async {
    setState(() {
      _loadingVillages = true;
      _villages = [];
      _selectedVillage = null;
    });

    try {
      final villages = await _regionService.getVillages(districtId);
      setState(() {
        _villages = villages;
        _loadingVillages = false;
      });
    } catch (e) {
      setState(() => _loadingVillages = false);
      print('[StudioPengaturan] Error loading villages: $e');
    }
  }

  Future<void> _onVillageSelected(Village village) async {
    setState(() => _selectedVillage = village);

    // Auto-fill postal code when village is selected
    await _autoFillPostalCode(village);
  }

  Future<void> _autoFillPostalCode(Village village) async {
    try {
      // Search postal code by village name
      final results = await _postalCodeService.searchByPlace(village.name);

      if (results != null && results.isNotEmpty) {
        final result = results.first;

        // Auto-fill postal code
        setState(() {
          _postalCodeController.text = result.code;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Kode Pos: ${result.code}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Try with district name if village search fails
        if (_selectedDistrict != null) {
          final districtResults = await _postalCodeService.searchByPlace(
            _selectedDistrict!.name,
          );
          if (districtResults != null && districtResults.isNotEmpty) {
            setState(() {
              _postalCodeController.text = districtResults.first.code;
            });
          }
        }
      }
    } catch (e) {
      print('[StudioPengaturan] Error auto-filling postal code: $e');
    }
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _logoFile = File(pickedFile.path);
        });

        // Auto-upload logo immediately
        await _uploadLogo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
      }
    }
  }

  Future<void> _uploadLogo() async {
    if (_logoFile == null) return;

    setState(() => _isUploadingLogo = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) throw Exception('Token tidak ditemukan');

      final url = await _uploadService.uploadImage(_logoFile!, 'logos', token);

      setState(() {
        _uploadedLogoUrl = url;
        _isUploadingLogo = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Logo berhasil diupload')),
        );
      }
    } catch (e) {
      setState(() => _isUploadingLogo = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal upload logo: $e')));
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFB45309)),
                title: const Text(
                  'Ambil Foto',
                  style: TextStyle(color: Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickLogo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFFB45309),
                ),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(color: Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickLogo(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== BANK SEARCH BOTTOM SHEET ==========
  void _showBankSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _BankSearchBottomSheet(
        currentBank: _selectedBank,
        onBankSelected: (bank) {
          setState(() {
            _selectedBank = bank.name;
            _selectedBankCode = bank.code;
          });
        },
      ),
    );
  }

  // ========== SAVE INFO TOKO ==========
  Future<void> _saveInfoToko() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingInfo = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) throw Exception('Token tidak ditemukan');

      final body = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'province': _selectedProvince?.name,
        'city': _selectedRegency?.name,
        'district': _selectedDistrict?.name,
        'village': _selectedVillage?.name,
        'address': _addressController.text.trim(),
        'postalCode': _postalCodeController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      // Add logo URL if uploaded
      if (_uploadedLogoUrl != null) {
        body['logoUrl'] = _uploadedLogoUrl;
      }

      final response = await _apiService.patch(
        '/api/studio/store',
        body: body,
        token: token,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Pengaturan toko tersimpan!')),
          );
        }

        // Clear uploaded logo state
        setState(() {
          _logoFile = null;
          _uploadedLogoUrl = null;
        });

        // Invalidate cache and reload
        _cachedStore = null;
        _cacheTime = null;
        await _loadStoreData();
      }

      setState(() => _isSavingInfo = false);
    } catch (e) {
      setState(() => _isSavingInfo = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
  }

  // ========== BANK OTP FLOW ==========
  Future<void> _sendOTPForBank() async {
    if (_selectedBank == null ||
        _bankAccountController.text.isEmpty ||
        _bankHolderController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua data rekening terlebih dahulu'),
        ),
      );
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await _apiService.post(
        '/api/auth/otp/send',
        body: {'type': 'bank_change'},
        token: token,
      );

      if (response['success'] == true) {
        setState(() => _otpSentForBank = true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP telah dikirim ke email Anda')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim OTP: $e')));
      }
    }
  }

  Future<void> _verifyBankOTP() async {
    if (_bankOtpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode OTP 6 digit')),
      );
      return;
    }

    setState(() => _isSavingBank = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) throw Exception('Token tidak ditemukan');

      final body = {
        'bankName': _selectedBank,
        'bankAccount': _bankAccountController.text.trim(),
        'bankHolder': _bankHolderController.text.trim(),
        'otp': _bankOtpController.text,
        'otpType': 'bank_change',
      };

      final response = await _apiService.patch(
        '/api/studio/store',
        body: body,
        token: token,
      );

      if (response['success'] == true) {
        setState(() {
          _showBankForm = false;
          _otpSentForBank = false;
          _bankOtpController.clear();
          _isSavingBank = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Rekening berhasil diverifikasi dan disimpan'),
            ),
          );
        }

        // Invalidate cache and reload
        _cachedStore = null;
        _cacheTime = null;
        await _loadStoreData();
      } else {
        setState(() => _isSavingBank = false);
      }
    } catch (e) {
      setState(() => _isSavingBank = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Verifikasi gagal: $e')));
      }
    }
  }

  // ========== UI ==========
  @override
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 80,
          ),
          children: [
            // Fee Platform Banner (Collapsible)
            _buildFeePlatformSection(),
            const SizedBox(height: 16),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Section 1: Info Toko
                  _buildInfoTokoSection(),
                  const SizedBox(height: 16),

                  // Section 2: Rekening Bank
                  _buildRekeningSection(),
                ],
              ),
            ),
          ],
        ),

        // Sticky Save Button for Info Toko only
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSavingInfo || _isUploadingLogo
                  ? null
                  : _saveInfoToko,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB45309),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSavingInfo
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Simpan Pengaturan Toko',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeePlatformSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          backgroundColor: const Color(0xFFFEF3C7),
          collapsedBackgroundColor: const Color(0xFFFEF3C7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFB45309), size: 20),
              SizedBox(width: 8),
              Text(
                'Info Fee Platform',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309),
                ),
              ),
            ],
          ),
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFEF3C7), Color(0xFFFBBF24)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeeRow('Upload & Publish', 'GRATIS'),
                  const SizedBox(height: 6),
                  _buildFeeRow('Fee Transaksi', '2.5%'),
                  const SizedBox(height: 6),
                  _buildFeeRow('Sertifikat Digital', 'GRATIS'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Contoh: Karya terjual Rp 1.000.000 → saat dicairkan diterima Rp 975.000 (fee 2.5% = Rp 25.000 dipotong saat pencairan)',
                      style: TextStyle(fontSize: 11, color: Color(0xFF78350F)),
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

  Widget _buildFeeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF78350F),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB45309),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTokoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.store, color: Color(0xFFB45309), size: 22),
                SizedBox(width: 10),
                Text(
                  'Informasi Toko',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Logo Upload
            const Text(
              'Logo Toko',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _isUploadingLogo
                    ? const Center(child: CircularProgressIndicator())
                    : _logoFile != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _logoFile!,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            ),
                          ),
                          if (_uploadedLogoUrl != null)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      )
                    : _store?.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _store!.logoUrl!.startsWith('http')
                              ? _store!.logoUrl!
                              : '$baseUrl${_store!.logoUrl!}',
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  color: Colors.grey[400],
                                  size: 36,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Gagal load',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Colors.grey[400],
                            size: 36,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Upload Logo',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Nama Toko
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Toko *',
                hintText: 'Nama studio/toko Anda',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),

            // Deskripsi
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Toko',
                hintText: 'Ceritakan tentang toko dan karya Anda...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            const Divider(),
            const SizedBox(height: 12),

            // Alamat Pickup Kurir Section
            const Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFFB45309), size: 20),
                SizedBox(width: 8),
                Text(
                  'Alamat Pickup Kurir',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alamat lengkap untuk pickup kurir dan kalkulasi ongkir',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Province Dropdown
            DropdownButtonFormField<Province>(
              value: _selectedProvince,
              decoration: const InputDecoration(
                labelText: 'Provinsi *',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: _provinces
                  .map(
                    (prov) => DropdownMenuItem(
                      value: prov,
                      child: Text(
                        prov.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedProvince = value);
                if (value != null) {
                  _loadRegencies(value.id);
                }
              },
              validator: (value) => value == null ? 'Pilih provinsi' : null,
            ),
            const SizedBox(height: 12),

            // Regency Dropdown
            DropdownButtonFormField<Regency>(
              value: _selectedRegency,
              decoration: const InputDecoration(
                labelText: 'Kota/Kabupaten *',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: _regencies
                  .map(
                    (reg) => DropdownMenuItem(
                      value: reg,
                      child: Text(
                        reg.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _selectedProvince == null
                  ? null
                  : (value) {
                      setState(() => _selectedRegency = value);
                      if (value != null) {
                        _loadDistricts(value.id);
                      }
                    },
              validator: (value) =>
                  value == null ? 'Pilih kota/kabupaten' : null,
            ),
            const SizedBox(height: 12),

            // District Dropdown
            DropdownButtonFormField<District>(
              value: _selectedDistrict,
              decoration: const InputDecoration(
                labelText: 'Kecamatan',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: _districts
                  .map(
                    (dist) => DropdownMenuItem(
                      value: dist,
                      child: Text(
                        dist.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _selectedRegency == null
                  ? null
                  : (value) {
                      setState(() => _selectedDistrict = value);
                      if (value != null) {
                        _loadVillages(value.id);
                      }
                    },
            ),
            const SizedBox(height: 12),

            // Village Dropdown
            DropdownButtonFormField<Village>(
              value: _selectedVillage,
              decoration: const InputDecoration(
                labelText: 'Kelurahan/Desa',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: _villages
                  .map(
                    (vill) => DropdownMenuItem(
                      value: vill,
                      child: Text(
                        vill.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _selectedDistrict == null
                  ? null
                  : (value) {
                      if (value != null) {
                        _onVillageSelected(value);
                      }
                    },
            ),
            const SizedBox(height: 12),

            // Address Line
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Alamat Jalan Lengkap *',
                hintText: 'Jl. Mawar No. 50 RT 03/RW 02',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              maxLines: 2,
              validator: (value) =>
                  value?.isEmpty == true ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),

            // Postal Code & Phone
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _postalCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Kode Pos *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'No. HP Pickup',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRekeningSection() {
    final hasBank = _store?.bankName != null && _store?.bankAccount != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance,
                  color: Color(0xFFB45309),
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Rekening Pencairan Dana',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (hasBank)
                  const Icon(
                    Icons.verified_user,
                    size: 18,
                    color: Colors.green,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (hasBank && !_showBankForm) ...[
              // Show saved bank info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Rekening Terverifikasi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_store!.bankName} - ${_store!.bankAccount}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'a.n. ${_store!.bankHolder ?? '-'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() => _showBankForm = true),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Ubah Rekening'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  side: const BorderSide(color: Color(0xFFB45309)),
                ),
              ),
            ] else ...[
              // Bank form
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasBank
                            ? 'Ubah rekening memerlukan verifikasi OTP via email'
                            : 'Set rekening memerlukan verifikasi OTP via email',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (!_otpSentForBank) ...[
                // Searchable Bank Picker
                GestureDetector(
                  onTap: _showBankSearchBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedBank ?? 'Pilih Bank *',
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedBank == null
                                  ? Colors.grey.shade600
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.search,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bankAccountController,
                  decoration: const InputDecoration(
                    labelText: 'No. Rekening *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bankHolderController,
                  decoration: const InputDecoration(
                    labelText: 'Atas Nama *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _sendOTPForBank,
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: const Text('Kirim OTP ke Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB45309),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                ),
              ] else ...[
                TextFormField(
                  controller: _bankOtpController,
                  decoration: const InputDecoration(
                    labelText: 'Kode OTP *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    helperText: 'Masukkan kode OTP yang dikirim ke email Anda',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          _otpSentForBank = false;
                          _bankOtpController.clear();
                        }),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isSavingBank ? null : _verifyBankOTP,
                        icon: _isSavingBank
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.verified, size: 18),
                        label: const Text('Simpan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB45309),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== BANK SEARCH BOTTOM SHEET ====================

class _BankSearchBottomSheet extends StatefulWidget {
  final String? currentBank;
  final Function(BankData) onBankSelected;

  const _BankSearchBottomSheet({
    required this.currentBank,
    required this.onBankSelected,
  });

  @override
  State<_BankSearchBottomSheet> createState() => _BankSearchBottomSheetState();
}

class _BankSearchBottomSheetState extends State<_BankSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<BankData> _filteredBanks = INDONESIA_BANKS;
  static const int _maxDisplayResults = 20;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredBanks = searchBanks(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayedBanks = _filteredBanks.take(_maxDisplayResults).toList();
    final hiddenCount = _filteredBanks.length - _maxDisplayResults;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilih Bank',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search Field
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Cari nama bank...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFB45309)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
          ),

          // Bank List
          Expanded(
            child: _filteredBanks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bank tidak ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coba kata kunci lain',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount:
                        displayedBanks.length + (hiddenCount > 0 ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == displayedBanks.length) {
                        // Show "more results" hint
                        return Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '+$hiddenCount bank lainnya. Ketik lebih spesifik.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final bank = displayedBanks[index];
                      final isSelected = widget.currentBank == bank.name;

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB45309).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            color: Color(0xFFB45309),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          bank.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFFB45309)
                                : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'Kode: ${bank.code}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFFB45309),
                              )
                            : null,
                        onTap: () {
                          widget.onBankSelected(bank);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
