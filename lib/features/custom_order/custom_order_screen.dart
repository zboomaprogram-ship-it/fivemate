import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/app_config_provider.dart';
import '../../core/theme/app_colors.dart';

class CustomOrderScreen extends ConsumerStatefulWidget {
  const CustomOrderScreen({super.key});

  @override
  ConsumerState<CustomOrderScreen> createState() => _CustomOrderScreenState();
}

class _CustomOrderScreenState extends ConsumerState<CustomOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _colorsController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSharing = false;

  @override
  void dispose() {
    _descController.dispose();
    _dimensionsController.dispose();
    _colorsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (_) {}
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'اختر مصدر الصورة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'المعرض (الاستوديو)',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'الكاميرا',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSharing = true;
    });

    final configAsync = ref.read(appConfigProvider);
    final config = configAsync.valueOrNull;
    final number = config?.whatsappNumber ?? '201092970736';

    final textBuffer = StringBuffer();
    textBuffer.writeln('🌸 طلب تصميم خاص - خامات هاندميد 🌸');
    textBuffer.writeln();
    textBuffer.writeln('👤 تفاصيل الطلب:');
    textBuffer.writeln(_descController.text);
    if (_dimensionsController.text.isNotEmpty) {
      textBuffer.writeln('📏 المقاسات/الأبعاد: ${_dimensionsController.text}');
    }
    if (_colorsController.text.isNotEmpty) {
      textBuffer.writeln('🎨 الألوان المفضلة: ${_colorsController.text}');
    }
    textBuffer.writeln();
    textBuffer.writeln('📞 للاستفسار والتأكيد عبر واتساب: wa.me/$number');

    final message = textBuffer.toString();

    try {
      if (_selectedImage != null) {
        await Share.shareXFiles(
          [XFile(_selectedImage!.path)],
          text: message,
          subject: 'طلب تصميم خاص - خامات',
        );
      } else {
        await Share.share(message, subject: 'طلب تصميم خاص - خامات');
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isSharing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم فتح نافذة المشاركة لإرسال طلبك!',
            style: TextStyle(fontFamily: 'Tajawal'),
            textAlign: TextAlign.center,
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'تنفيذ منتجك الخاص حسب الطلب',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'هل تبحثين عن قطعة مصممة خصيصاً لكِ؟ أرسلي لنا التفاصيل والصورة وسنتواصل معكِ لتنفيذها!',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMedium,
                            fontFamily: 'Tajawal',
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Description Field
                const Text(
                  'تفاصيل التصميم المطلوب *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'يرجى كتابة وصف للتصميم المطلوب'
                      : null,
                  decoration: InputDecoration(
                    hintText:
                        'اكتبي هنا مقاس القطعة، الخامات المطلوبة، وأي تفاصيل أخرى...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Additional details (Dimensions & Colors)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المقاسات / الأبعاد (اختياري)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _dimensionsController,
                            decoration: InputDecoration(
                              hintText: 'مثال: 50 × 50 سم',
                              hintStyle: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الألوان المفضلة (اختياري)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _colorsController,
                            decoration: InputDecoration(
                              hintText: 'مثال: روز غولد، بيج',
                              hintStyle: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Image Upload Area
                const Text(
                  'صورة توضيحية للتصميم (اختياري)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(_selectedImage!, fit: BoxFit.cover),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black.withOpacity(
                                      0.6,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _selectedImage = null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 48,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'اضغطي لإضافة صورة من المعرض أو الكاميرا',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 36),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSharing ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                    child: _isSharing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.share, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'مشاركة وتأكيد عبر واتساب',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
