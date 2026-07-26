import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/address.dart';
import '../models/region.dart';
import '../providers/auth_provider.dart';
import '../services/address_service.dart';
import '../services/region_service.dart';
import '../services/geocoding_service.dart';
import '../services/postal_code_service.dart';

class AddressFormScreen extends StatefulWidget {
  final Address? address;

  const AddressFormScreen({super.key, this.address});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _zipController = TextEditingController();
  final MapController _mapController = MapController();

  final AddressService _addressService = AddressService();
  final RegionService _regionService = RegionService();
  final GeocodingService _geocodingService = GeocodingService();
  final PostalCodeService _postalCodeService = PostalCodeService();

  String _selectedLabel = 'Rumah';
  bool _isDefault = false;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  bool _isRestoringAddress = false;  // Flag to prevent clearing fields during restore

  // Jakarta City Center (Monas) - more accurate default location
  LatLng _currentLocation = const LatLng(-6.1751, 106.8650);

  // Region data
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

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    _checkLocationPermission();
    
    if (widget.address != null) {
      _loadExistingAddress();
    }
  }

  void _loadExistingAddress() {
    final address = widget.address!;
    _nameController.text = address.name;
    _phoneController.text = address.phone;
    _addressController.text = address.address;
    _zipController.text = address.zip;
    _selectedLabel = address.label;
    _isDefault = address.isDefault;
    
    // Set flag to prevent clearing postal code during restore
    _isRestoringAddress = true;
    
    // Load and restore region selections
    _restoreRegionSelections(address).then((_) {
      // Restore complete, allow clearing on manual changes
      _isRestoringAddress = false;
    });
  }

  Future<void> _restoreRegionSelections(Address address) async {
    // Wait for provinces to load
    while (_provinces.isEmpty && _loadingProvinces) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_provinces.isEmpty) return;

    // 1. Match and select Province
    final provinceId = _postalCodeService.findMatchingId(
      address.province,
      _provinces,
      (p) => p.name,
      (p) => p.id,
    );

    if (provinceId != null) {
      final province = _provinces.firstWhere((p) => p.id == provinceId);
      setState(() => _selectedProvince = province);
      await _loadRegencies(provinceId);

      // 2. Match and select Regency/City
      final regencyId = _postalCodeService.findMatchingId(
        address.city,
        _regencies,
        (r) => r.name,
        (r) => r.id,
      );

      if (regencyId != null) {
        final regency = _regencies.firstWhere((r) => r.id == regencyId);
        setState(() => _selectedRegency = regency);

        // Only load districts if we have district data
        if (address.district != null && address.district!.isNotEmpty) {
          await _loadDistricts(regencyId);

          // 3. Match and select District
          final districtId = _postalCodeService.findMatchingId(
            address.district!,
            _districts,
            (d) => d.name,
            (d) => d.id,
          );

          if (districtId != null) {
            final district = _districts.firstWhere((d) => d.id == districtId);
            setState(() => _selectedDistrict = district);

            // Only load villages if we have village data
            if (address.village != null && address.village!.isNotEmpty) {
              await _loadVillages(districtId);

              // 4. Match and select Village
              final villageId = _postalCodeService.findMatchingId(
                address.village!,
                _villages,
                (v) => v.name,
                (v) => v.id,
              );

              if (villageId != null) {
                final village = _villages.firstWhere((v) => v.id == villageId);
                setState(() => _selectedVillage = village);
              }
            }
          }
        }
      }
    }
  }

  Future<void> _loadProvinces() async {
    setState(() => _loadingProvinces = true);
    try {
      final provinces = await _regionService.getProvinces();
      setState(() {
        _provinces = provinces;
        _loadingProvinces = false;
      });
    } catch (e) {
      setState(() => _loadingProvinces = false);
      print('[AddressForm] Error loading provinces: $e');
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
      // Clear postal code when changing province (but not during restore)
      if (!_isRestoringAddress) {
        _zipController.clear();
      }
    });
    
    try {
      final regencies = await _regionService.getRegencies(provinceId);
      setState(() {
        _regencies = regencies;
        _loadingRegencies = false;
      });
    } catch (e) {
      setState(() => _loadingRegencies = false);
      print('[AddressForm] Error loading regencies: $e');
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
      print('[AddressForm] Error loading districts: $e');
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
      print('[AddressForm] Error loading villages: $e');
    }
  }

  Future<void> _onVillageSelected(Village village) async {
    setState(() => _selectedVillage = village);
    
    // Auto-fill postal code and map location when village is selected
    await _autoFillFromVillageSelection(village);
  }

  Future<void> _autoFillFromVillageSelection(Village village) async {
    try {
      // Search postal code by village name
      final results = await _postalCodeService.searchByPlace(village.name);
      
      if (results != null && results.isNotEmpty) {
        final result = results.first;
        
        // Auto-fill postal code
        setState(() {
          _zipController.text = result.code;
          _currentLocation = LatLng(result.latitude, result.longitude);
        });

        // Auto-center map to village location
        _mapController.move(_currentLocation, 15.0);

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
        // If no exact match, try with district name
        final districtResults = await _postalCodeService.searchByPlace(
          _selectedDistrict?.name ?? '',
        );
        
        if (districtResults != null && districtResults.isNotEmpty) {
          final result = districtResults.first;
          setState(() {
            _zipController.text = result.code;
            _currentLocation = LatLng(result.latitude, result.longitude);
          });
          _mapController.move(_currentLocation, 14.0);
        }
      }
    } catch (e) {
      print('[AddressForm] Error auto-filling from village: $e');
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _mapController.move(_currentLocation, 16.0);
      
      // Use PostalCodeService to detect and auto-fill from GPS
      await _autoFillFromGPS(position.latitude, position.longitude);
      
      setState(() => _isLoadingLocation = false);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendapatkan lokasi GPS. Pastikan GPS aktif dan izin lokasi diberikan.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _autoFillFromGPS(double latitude, double longitude) async {
    try {
      final result = await _postalCodeService.detectByCoordinates(latitude, longitude);
      
      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat mendeteksi alamat dari lokasi ini'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Auto-fill postal code
      setState(() {
        _zipController.text = result.code;
      });

      // Try to match and auto-select regions
      await _matchAndSelectRegions(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 ${result.village}, ${result.district}, ${result.regency}, ${result.province}'),
            backgroundColor: const Color(0xFF653611),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('[AddressForm] Error auto-filling from GPS: $e');
    }
  }

  Future<void> _matchAndSelectRegions(PostalCodeResult result) async {
    // 1. Match Province
    final provinceId = _postalCodeService.findMatchingId(
      result.province,
      _provinces,
      (p) => p.name,
      (p) => p.id,
    );

    if (provinceId != null) {
      final province = _provinces.firstWhere((p) => p.id == provinceId);
      setState(() => _selectedProvince = province);
      await _loadRegencies(provinceId);

      // 2. Match Regency
      final regencyId = _postalCodeService.findMatchingId(
        result.regency,
        _regencies,
        (r) => r.name,
        (r) => r.id,
      );

      if (regencyId != null) {
        final regency = _regencies.firstWhere((r) => r.id == regencyId);
        setState(() => _selectedRegency = regency);
        await _loadDistricts(regencyId);

        // 3. Match District
        final districtId = _postalCodeService.findMatchingId(
          result.district,
          _districts,
          (d) => d.name,
          (d) => d.id,
        );

        if (districtId != null) {
          final district = _districts.firstWhere((d) => d.id == districtId);
          setState(() => _selectedDistrict = district);
          await _loadVillages(districtId);

          // 4. Match Village
          final villageId = _postalCodeService.findMatchingId(
            result.village,
            _villages,
            (v) => v.name,
            (v) => v.id,
          );

          if (villageId != null) {
            final village = _villages.firstWhere((v) => v.id == villageId);
            setState(() => _selectedVillage = village);
          }
        }
      }
    }
  }

  Future<void> _reverseGeocode() async {
    // Map tap detection - show location info
    try {
      final result = await _postalCodeService.detectByCoordinates(
        _currentLocation.latitude,
        _currentLocation.longitude,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 ${result.village}, ${result.district}\nKode Pos: ${result.code}'),
            duration: const Duration(seconds: 3),
            backgroundColor: const Color(0xFF653611),
            action: SnackBarAction(
              label: 'ISI FORM',
              textColor: Colors.white,
              onPressed: () => _autoFillFromGPS(_currentLocation.latitude, _currentLocation.longitude),
            ),
          ),
        );
      }
    } catch (e) {
      print('[AddressForm] Error reverse geocoding: $e');
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvince == null || _selectedRegency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih provinsi dan kota terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final data = {
        'label': _selectedLabel,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _selectedRegency!.name,
        'province': _selectedProvince!.name,
        'district': _selectedDistrict?.name,  // Added
        'village': _selectedVillage?.name,    // Added
        'zip': _zipController.text.trim(),
        'isDefault': _isDefault,
      };

      if (widget.address != null) {
        // Update existing address
        await _addressService.updateAddress(token, widget.address!.id, data);
      } else {
        // Create new address
        await _addressService.createAddress(token, data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.address != null
                  ? 'Alamat berhasil diperbarui'
                  : 'Alamat berhasil ditambahkan',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan alamat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _zipController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.address != null ? 'Edit Alamat' : 'Tambah Alamat',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMapSection(),
            const SizedBox(height: 24),
            _buildLabelSection(),
            const SizedBox(height: 24),
            _buildFormFields(),
            const SizedBox(height: 24),
            _buildDefaultCheckbox(),
            const SizedBox(height: 24),
            _buildSaveButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _currentLocation,
                    zoom: 15.0,
                    onTap: (tapPosition, latLng) {
                      setState(() => _currentLocation = latLng);
                      _reverseGeocode();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.majacraft.mobile',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFF653611),
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    backgroundColor: Colors.white,
                    child: _isLoadingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, color: Color(0xFF653611)),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Tap peta atau tombol GPS untuk memilih lokasi (opsional)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LABEL ALAMAT',
          style: TextStyle(
            color: Color(0xFF653611),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildLabelChip('Rumah', Icons.home),
            const SizedBox(width: 8),
            _buildLabelChip('Kantor', Icons.business),
            const SizedBox(width: 8),
            _buildLabelChip('Lainnya', Icons.location_on),
          ],
        ),
      ],
    );
  }

  Widget _buildLabelChip(String label, IconData icon) {
    final isSelected = _selectedLabel == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedLabel = label),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF653611) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF653611) : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('NAMA PENERIMA'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _nameController,
          hintText: 'Masukkan nama penerima',
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nama penerima tidak boleh kosong';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildLabel('NOMOR TELEPON'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _phoneController,
          hintText: 'Masukkan nomor telepon',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(15),
          ],
        ),
        const SizedBox(height: 16),
        _buildLabel('PROVINSI'),
        const SizedBox(height: 8),
        _buildDropdown<Province>(
          value: _selectedProvince,
          hint: 'Pilih Provinsi',
          items: _provinces,
          isLoading: _loadingProvinces,
          onChanged: (province) {
            setState(() => _selectedProvince = province);
            if (province != null) {
              _loadRegencies(province.id);
            }
          },
          itemLabel: (province) => province.name,
        ),
        const SizedBox(height: 16),
        _buildLabel('KOTA/KABUPATEN'),
        const SizedBox(height: 8),
        _buildDropdown<Regency>(
          value: _selectedRegency,
          hint: 'Pilih Kota/Kabupaten',
          items: _regencies,
          isLoading: _loadingRegencies,
          enabled: _selectedProvince != null,
          onChanged: (regency) {
            setState(() => _selectedRegency = regency);
            if (regency != null) {
              _loadDistricts(regency.id);
            }
          },
          itemLabel: (regency) => regency.name,
        ),
        const SizedBox(height: 16),
        _buildLabel('KECAMATAN'),
        const SizedBox(height: 8),
        _buildDropdown<District>(
          value: _selectedDistrict,
          hint: 'Pilih Kecamatan',
          items: _districts,
          isLoading: _loadingDistricts,
          enabled: _selectedRegency != null,
          onChanged: (district) {
            setState(() => _selectedDistrict = district);
            if (district != null) {
              _loadVillages(district.id);
            }
          },
          itemLabel: (district) => district.name,
        ),
        const SizedBox(height: 16),
        _buildLabel('KELURAHAN/DESA'),
        const SizedBox(height: 8),
        _buildDropdown<Village>(
          value: _selectedVillage,
          hint: 'Pilih Kelurahan/Desa',
          items: _villages,
          isLoading: _loadingVillages,
          enabled: _selectedDistrict != null,
          onChanged: (village) {
            if (village != null) {
              _onVillageSelected(village);
            }
          },
          itemLabel: (village) => village.name,
        ),
        const SizedBox(height: 16),
        _buildLabel('ALAMAT LENGKAP'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _addressController,
          hintText: 'Jalan, RT/RW, Nomor rumah, dll',
          prefixIcon: Icons.home_outlined,
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Alamat lengkap tidak boleh kosong';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildLabel('KODE POS'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _zipController,
          hintText: 'Masukkan kode pos',
          prefixIcon: Icons.markunread_mailbox_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Kode pos tidak boleh kosong';
            }
            if (value.length != 5) {
              return 'Kode pos harus 5 digit';
            }
            return null;
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Masukkan kode pos sesuai dengan kelurahan/desa Anda',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF653611),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF653611), size: 22),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF653611), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required bool isLoading,
    bool enabled = true,
    required void Function(T?) onChanged,
    required String Function(T) itemLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.grey[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[400])),
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          borderRadius: BorderRadius.circular(12),
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          items: enabled && !isLoading
              ? items.map((item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      itemLabel(item),
                      style: const TextStyle(fontSize: 15),
                    ),
                  );
                }).toList()
              : [],
          onChanged: enabled && !isLoading ? onChanged : null,
        ),
      ),
    );
  }

  Widget _buildDefaultCheckbox() {
    return InkWell(
      onTap: () => setState(() => _isDefault = !_isDefault),
      child: Row(
        children: [
          Checkbox(
            value: _isDefault,
            onChanged: (value) => setState(() => _isDefault = value ?? false),
            activeColor: const Color(0xFF653611),
          ),
          const Text(
            'Jadikan sebagai alamat utama',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveAddress,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF653611),
          disabledBackgroundColor: Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Simpan Alamat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
