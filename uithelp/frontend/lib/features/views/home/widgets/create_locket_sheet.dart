import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../features/viewmodels/locket_viewmodel.dart';

class CreateLocketSheet extends StatefulWidget {
  const CreateLocketSheet({super.key});

  @override
  State<CreateLocketSheet> createState() => _CreateLocketSheetState();
}

class _CreateLocketSheetState extends State<CreateLocketSheet> {
  final _captionCtrl = TextEditingController();
  XFile? _pickedImage;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final img = await _picker.pickImage(source: source, imageQuality: 85);
    if (img != null) setState(() => _pickedImage = img);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A2235) : Colors.white;
    final vm = context.watch<LocketViewModel>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.camera_alt_rounded, color: Color(0xFFFF6B6B), size: 22),
                const SizedBox(width: 10),
                Text(
                  'Tạo Locket mới',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF050505),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded,
                      color: isDark ? Colors.white38 : Colors.grey[500]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Image picker area
                  GestureDetector(
                    onTap: () => _showPickerOptions(context),
                    child: Container(
                      width: double.infinity,
                      height: 260,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: _pickedImage == null
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFFFF6B6B).withOpacity(0.08),
                                  const Color(0xFFFF8E53).withOpacity(0.08),
                                ],
                              )
                            : null,
                        border: Border.all(
                          color: _pickedImage == null
                              ? const Color(0xFFFF6B6B).withOpacity(0.3)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _pickedImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFFF6B6B).withOpacity(0.2),
                                        const Color(0xFFFF8E53).withOpacity(0.2),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo_rounded,
                                    color: Color(0xFFFF6B6B),
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Chọn ảnh',
                                  style: TextStyle(
                                    color: Color(0xFFFF6B6B),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Nhấn để chọn từ thư viện hoặc chụp ảnh',
                                  style: TextStyle(
                                    color: isDark ? Colors.white38 : Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  File(_pickedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _pickedImage = null),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded,
                                          color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => _showPickerOptions(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit_rounded,
                                              color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text('Đổi ảnh',
                                              style: TextStyle(
                                                  color: Colors.white, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Caption
                  TextField(
                    controller: _captionCtrl,
                    decoration: InputDecoration(
                      hintText: 'Thêm caption (tuỳ chọn)...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey[500],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFF0F2F5),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1C1E21),
                    ),
                    maxLines: 3,
                    maxLength: 200,
                  ),
                ],
              ),
            ),
          ),
          // Submit button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_pickedImage == null || vm.isCreating)
                    ? null
                    : () => _submit(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: _pickedImage != null
                        ? const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                          )
                        : null,
                    color: _pickedImage == null ? Colors.grey.shade300 : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: vm.isCreating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Đăng Locket',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A2235)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB)),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFFFF6B6B)),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (_pickedImage == null) return;
    final vm = context.read<LocketViewModel>();
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        _pickedImage!.path,
        filename: _pickedImage!.name,
      ),
      if (_captionCtrl.text.trim().isNotEmpty)
        'caption': _captionCtrl.text.trim(),
    });
    final ok = await vm.createLocket(formData);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng locket thành công'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Đăng thất bại')),
      );
    }
  }
}
