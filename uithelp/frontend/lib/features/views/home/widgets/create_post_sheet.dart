import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../features/viewmodels/post_viewmodel.dart';

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({super.key});

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _type = 'lost';
  String? _selectedLocation;
  File? _image;

  static const _locations = [
    'Tòa A', 'Tòa B', 'Tòa C', 'Tòa D', 'Tòa E',
    'Thư Viện', 'Cổng trước', 'Cổng sau',
    'Nhà xe', 'Nhà ăn', 'Khuôn viên', 'Không xác định',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<PostViewModel>();

    final formData = FormData.fromMap({
      'type': _type,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'location': _selectedLocation ?? 'Không xác định',
      'contact': _contactCtrl.text.trim(),
      if (_image != null)
        'image': await MultipartFile.fromFile(_image!.path,
            filename: _image!.path.split('/').last),
    });

    final ok = await vm.createPost(formData);
    if (ok && mounted) Navigator.pop(context);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(vm.errorMessage ?? 'Lỗi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final vm = context.watch<PostViewModel>();

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Đăng bài mới',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                const SizedBox(height: 16),
                // type selector
                Row(
                  children: [
                    _typeChip('lost', 'Mất đồ', AppColors.error, isDark, cs),
                    const SizedBox(width: 10),
                    _typeChip('found', 'Tìm thấy', AppColors.success, isDark, cs),
                  ],
                ),
                const SizedBox(height: 14),
                _field('Tên đồ vật *', _titleCtrl, isDark, cs,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Vui lòng nhập tên đồ vật' : null),
                const SizedBox(height: 10),
                _locationDropdown(isDark, cs),
                const SizedBox(height: 10),
                _field('Liên hệ', _contactCtrl, isDark, cs,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                _field('Mô tả', _descCtrl, isDark, cs, maxLines: 3),
                const SizedBox(height: 14),
                // image picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkInputFill
                          : AppColors.lightInputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark
                              ? AppColors.darkInputBorder
                              : AppColors.lightInputBorder),
                    ),
                    child: _image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_image!, fit: BoxFit.cover))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 32,
                                  color: isDark
                                      ? AppColors.darkTextHint
                                      : AppColors.lightTextHint),
                              const SizedBox(height: 4),
                              Text('Thêm ảnh',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.darkTextHint
                                          : AppColors.lightTextHint)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: vm.isCreating ? null : _submit,
                    child: vm.isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Đăng bài'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationDropdown(bool isDark, ColorScheme cs) {
    return DropdownButtonFormField<String>(
      value: _selectedLocation,
      hint: Text('Vị trí',
          style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint)),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: isDark ? AppColors.darkInputBorder : AppColors.lightInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: isDark ? AppColors.darkInputBorder : AppColors.lightInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      ),
      dropdownColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      style: TextStyle(fontSize: 14, color: cs.onSurface),
      items: _locations
          .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
          .toList(),
      onChanged: (val) => setState(() => _selectedLocation = val),
    );
  }

  Widget _typeChip(String value, String label, Color color, bool isDark,
      ColorScheme cs) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }

  Widget _field(String hint, TextEditingController ctrl, bool isDark,
      ColorScheme cs,
      {int maxLines = 1,
      TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: 14, color: cs.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color:
                isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
        filled: true,
        fillColor:
            isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: isDark
                  ? AppColors.darkInputBorder
                  : AppColors.lightInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: isDark
                  ? AppColors.darkInputBorder
                  : AppColors.lightInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      ),
    );
  }
}
