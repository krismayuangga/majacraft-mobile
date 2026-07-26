import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/studio_product.dart';
import '../../widgets/simple_markdown_editor.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

// Custom TextInputFormatter untuk format harga dengan separator ribuan
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }

    // Format with thousands separator
    final formatted = _formatWithSeparator(digitsOnly);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithSeparator(String value) {
    final buffer = StringBuffer();
    final length = value.length;

    for (int i = 0; i < length; i++) {
      buffer.write(value[i]);
      final position = length - i - 1;
      if (position > 0 && position % 3 == 0) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  // Form controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _originController = TextEditingController();
  final _materialController = TextEditingController();
  final _tagsController = TextEditingController();

  // Form state
  List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  List<Category> _categories = [];
  String? _selectedCategoryId;
  String _selectedKondisi = 'Baru';
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _originController.dispose();
    _materialController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await ApiService().get('/api/categories');
      if (response['success']) {
        final categoriesData = response['data'] as List;
        setState(() {
          _categories = categoriesData
              .map((c) => Category.fromJson(c))
              .toList();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat kategori: $e';
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maksimal 5 foto')));
      return;
    }

    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 85, // Compress to reduce file size
      );

      if (pickedFiles != null) {
        final remainingSlots = 5 - _selectedImages.length;
        final validFiles = <File>[];

        for (var xFile in pickedFiles.take(remainingSlots)) {
          if (_isValidImageFormat(xFile.path)) {
            validFiles.add(File(xFile.path));
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'File ${xFile.name} diabaikan. Hanya JPG, PNG, WebP yang didukung.',
                  ),
                ),
              );
            }
          }
        }

        if (validFiles.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(validFiles);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maksimal 5 foto')));
      return;
    }

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Compress to reduce file size
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  String _getContentType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // default fallback
    }
  }

  bool _isValidImageFormat(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'webp'].contains(extension);
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      // Validate format first
      if (!_isValidImageFormat(imageFile.path)) {
        throw Exception('Format tidak didukung. Gunakan JPG, PNG, atau WebP');
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://majacraft.id/api/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Get content type based on file extension
      final contentType = _getContentType(imageFile.path);
      final mediaType = MediaType.parse(contentType);

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: mediaType,
        ),
      );

      print('Uploading image: ${imageFile.path}');
      print('Content-Type: $contentType');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('Upload response: $responseBody');

      final jsonResponse = jsonDecode(responseBody);

      if (jsonResponse['success'] == true) {
        return jsonResponse['data']['url'] as String;
      } else {
        print('Upload failed: ${jsonResponse['error']}');
        throw Exception(jsonResponse['error'] ?? 'Upload gagal');
      }
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 foto produk')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih kategori produk')));
      return;
    }

    // Validate originalPrice > price
    final price = int.parse(
      _priceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );

    if (_originalPriceController.text.isNotEmpty) {
      final originalPrice = int.parse(
        _originalPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );

      if (originalPrice <= price) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harga coret harus lebih tinggi dari harga jual'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      // Upload all images first
      _uploadedImageUrls.clear();
      for (var imageFile in _selectedImages) {
        final url = await _uploadImage(imageFile);
        if (url != null) {
          _uploadedImageUrls.add(url);
        }
      }

      if (_uploadedImageUrls.isEmpty) {
        throw Exception('Gagal mengupload gambar');
      }

      // Prepare product data
      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': int.parse(
          _priceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ),
        'originalPrice': _originalPriceController.text.isNotEmpty
            ? int.parse(
                _originalPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
              )
            : null,
        'stock': int.parse(_stockController.text),
        'categoryId': _selectedCategoryId,
        'weight': _weightController.text.isNotEmpty
            ? (double.parse(_weightController.text.replaceAll(',', '.')) * 1000)
                  .toInt()
            : null,
        'length': _lengthController.text.isNotEmpty
            ? int.parse(_lengthController.text)
            : null,
        'width': _widthController.text.isNotEmpty
            ? int.parse(_widthController.text)
            : null,
        'height': _heightController.text.isNotEmpty
            ? int.parse(_heightController.text)
            : null,
        'origin': _originController.text.trim().isNotEmpty
            ? _originController.text.trim()
            : null,
        'material': _materialController.text.trim().isNotEmpty
            ? _materialController.text.trim()
            : null,
        'kondisi': _selectedKondisi,
        'tags': _tagsController.text.trim().isNotEmpty
            ? _tagsController.text
                  .trim()
                  .split(',')
                  .map((t) => t.trim())
                  .toList()
            : [],
        'imageUrls': _uploadedImageUrls,
      };

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();
      final response = await apiService.post(
        '/api/studio/products',
        body: productData,
        token: authProvider.token,
      );

      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produk berhasil ditambahkan!')),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        throw Exception(response['error'] ?? 'Gagal menambahkan produk');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1A14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tambah Karya Baru',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoadingCategories
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB45309)),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Images Section
                  _buildSectionHeader(
                    'Foto Produk',
                    'Maks 5 foto, foto pertama jadi cover',
                  ),
                  const SizedBox(height: 12),
                  _buildImagesSection(),
                  const SizedBox(height: 24),

                  // Basic Info
                  _buildSectionHeader('Informasi Dasar', 'Wajib diisi'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nama Karya',
                    hint: 'Contoh: Patung Ganesha Batu Andesit',
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Kategori',
                    value: _selectedCategoryId,
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _priceController,
                          label: 'Harga Jual',
                          hint: '450.000',
                          keyboardType: TextInputType.number,
                          prefix: 'Rp ',
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _originalPriceController,
                          label: 'Harga Coret',
                          hint: '600.000',
                          keyboardType: TextInputType.number,
                          prefix: 'Rp ',
                          helperText: 'Harus > harga jual',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _stockController,
                    label: 'Stok',
                    hint: '10',
                    keyboardType: TextInputType.number,
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  SimpleMarkdownEditor(
                    controller: _descriptionController,
                    label: 'Deskripsi',
                    hint:
                        'Ceritakan detail tentang karya Anda...\n\nContoh:\n**Patung Ganesha** ini dibuat dari batu andesit pilihan.\n\nKeunggulan:\n- Tahan lama\n- Detail halus\n- Cocok untuk taman',
                    maxLines: 8,
                    required: true,
                  ),
                  const SizedBox(height: 24),

                  // Detail Info
                  _buildSectionHeader(
                    'Informasi Detail',
                    'Opsional, tapi disarankan',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _weightController,
                    label: 'Berat (Kg)',
                    hint: '1.5',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    helperText:
                        'Minimum 0.1 Kg (100 gram) untuk perhitungan ongkir',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _lengthController,
                          label: 'Panjang (cm)',
                          hint: '20',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          controller: _widthController,
                          label: 'Lebar (cm)',
                          hint: '15',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          controller: _heightController,
                          label: 'Tinggi (cm)',
                          hint: '25',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _originController,
                    label: 'Asal Daerah',
                    hint: 'Yogyakarta',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _materialController,
                    label: 'Bahan/Material',
                    hint: 'Batu Andesit',
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Kondisi',
                    value: _selectedKondisi,
                    items: const [
                      DropdownMenuItem(value: 'Baru', child: Text('Baru')),
                      DropdownMenuItem(
                        value: 'Bekas - Sangat Baik',
                        child: Text('Bekas - Sangat Baik'),
                      ),
                      DropdownMenuItem(
                        value: 'Bekas - Baik',
                        child: Text('Bekas - Baik'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedKondisi = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _tagsController,
                    label: 'Tags',
                    hint: 'ganesha, batu, antik',
                    helperText: 'Pisahkan dengan koma',
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB45309),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Simpan Karya',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1C1A14),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      children: [
        // Image Grid
        if (_selectedImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                      image: DecorationImage(
                        image: FileImage(_selectedImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB45309),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Cover',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        const SizedBox(height: 12),

        // Add Image Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedImages.length < 5 ? _pickImages : null,
                icon: const Icon(Icons.photo_library, size: 20),
                label: const Text('Galeri'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  side: const BorderSide(color: Color(0xFFB45309)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedImages.length < 5 ? _takePhoto : null,
                icon: const Icon(Icons.camera_alt, size: 20),
                label: const Text('Kamera'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  side: const BorderSide(color: Color(0xFFB45309)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? prefix,
    String? helperText,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    // Determine input formatters based on field type
    List<TextInputFormatter>? formatters;

    if (label.contains('Harga')) {
      // Format harga dengan separator ribuan
      formatters = [
        FilteringTextInputFormatter.digitsOnly,
        ThousandsSeparatorInputFormatter(),
      ];
    } else if (keyboardType == TextInputType.number) {
      formatters = [FilteringTextInputFormatter.digitsOnly];
    } else if (keyboardType?.toString().contains('decimal') == true) {
      // Allow decimal for weight (Kg)
      formatters = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1A14),
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            helperStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            prefixText: prefix,
            prefixStyle: const TextStyle(
              color: Color(0xFF1C1A14),
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFB45309), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$label wajib diisi';
                  }
                  return null;
                }
              : null,
          inputFormatters: formatters,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1A14),
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFB45309), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '$label wajib dipilih';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }
}
