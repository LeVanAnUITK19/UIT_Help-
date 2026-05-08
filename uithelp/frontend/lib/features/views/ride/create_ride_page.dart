import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../features/viewmodels/ride_viewmodel.dart';
import 'widgets/ride_filter_bar.dart';
import '../../../data/models/ride_model.dart';

class CreateRidePage extends StatefulWidget {
  const CreateRidePage({super.key});

  @override
  State<CreateRidePage> createState() => _CreateRidePageState();
}

class _CreateRidePageState extends State<CreateRidePage> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'find';
  LocationModel? _from;
  LocationModel? _to;
  DateTime _departureTime = DateTime.now().add(const Duration(hours: 1));
  final _descCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();

  @override
  void dispose() {
    _descCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departureTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.uitBlue),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departureTime),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.uitBlue),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _departureTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn điểm xuất phát và điểm đến')),
      );
      return;
    }
    if (_from!.id == _to!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Điểm xuất phát và điểm đến không được giống nhau')),
      );
      return;
    }

    final vm = context.read<RideViewModel>();
    final result = await vm.createRide({
      'type': _type,
      'from': _from!.toJson(),
      'to': _to!.toJson(),
      'departureTime': _departureTime.toIso8601String(),
      'description': _descCtrl.text.trim(),
      'contact': _contactCtrl.text.trim(),
    });

    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng lịch đi học thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Có lỗi xảy ra'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final inputFill = isDark ? AppColors.darkInputFill : AppColors.lightInputFill;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rủ đi học chung',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Type selector ────────────────────────────────────────────────
            _SectionLabel(label: 'Bạn muốn làm gì?', textSecondary: textSecondary),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TypeCard(
                    icon: Icons.search_rounded,
                    label: 'Tìm bạn đi cùng',
                    subtitle: 'Mình cần người đi chung',
                    selected: _type == 'find',
                    color: AppColors.uitBlue,
                    onTap: () => setState(() => _type = 'find'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeCard(
                    icon: Icons.directions_bike_rounded,
                    label: 'Rủ bạn đi cùng',
                    subtitle: 'Mình có xe, muốn đi cùng',
                    selected: _type == 'offer',
                    color: AppColors.success,
                    onTap: () => setState(() => _type = 'offer'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── From ─────────────────────────────────────────────────────────
            _SectionLabel(label: 'Xuất phát từ', textSecondary: textSecondary),
            const SizedBox(height: 8),
            _LocationPicker(
              hint: 'Chọn điểm xuất phát',
              value: _from,
              fill: inputFill,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onChanged: (v) => setState(() => _from = v),
            ),
            const SizedBox(height: 16),

            // ── To ───────────────────────────────────────────────────────────
            _SectionLabel(label: 'Đến', textSecondary: textSecondary),
            const SizedBox(height: 8),
            _LocationPicker(
              hint: 'Chọn điểm đến',
              value: _to,
              fill: inputFill,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onChanged: (v) => setState(() => _to = v),
            ),
            const SizedBox(height: 16),

            // ── Departure time ───────────────────────────────────────────────
            _SectionLabel(label: 'Thời gian khởi hành', textSecondary: textSecondary),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: inputFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        color: AppColors.uitBlue, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _formatDateTime(_departureTime),
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.edit_rounded, size: 16, color: textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Description ──────────────────────────────────────────────────
            _SectionLabel(label: 'Ghi chú thêm (tuỳ chọn)', textSecondary: textSecondary),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              style: TextStyle(color: textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ví dụ: Mình đi lúc 7h, ai cùng đường nhắn mình nhé!',
                hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 16),

            // ── Contact ──────────────────────────────────────────────────────
            _SectionLabel(label: 'Liên hệ (Zalo, SĐT...)', textSecondary: textSecondary),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contactCtrl,
              style: TextStyle(color: textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Số điện thoại hoặc Zalo của bạn',
                hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.phone_rounded,
                    color: AppColors.uitBlue, size: 18),
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit ───────────────────────────────────────────────────────
            Consumer<RideViewModel>(
              builder: (_, vm, __) => GestureDetector(
                onTap: vm.isCreating ? null : _submit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: vm.isCreating
                          ? [Colors.grey, Colors.grey]
                          : [AppColors.uitBlue, AppColors.slateBlue],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: vm.isCreating
                        ? []
                        : [
                            BoxShadow(
                              color: AppColors.uitBlue.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Center(
                    child: vm.isCreating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Đăng lịch đi học',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$h:$m - $d/$mo/${dt.year}';
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color textSecondary;
  const _SectionLabel({required this.label, required this.textSecondary});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.3,
        ),
      );
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.1)
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey.withOpacity(0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: selected ? color : Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: selected ? color.withOpacity(0.7) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationPicker extends StatelessWidget {
  final String hint;
  final LocationModel? value;
  final Color fill;
  final Color textPrimary;
  final Color textSecondary;
  final void Function(LocationModel?) onChanged;

  const _LocationPicker({
    required this.hint,
    required this.value,
    required this.fill,
    required this.textPrimary,
    required this.textSecondary,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LocationModel>(
          value: value,
          hint: Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: AppColors.uitBlue, size: 18),
              const SizedBox(width: 8),
              Text(hint,
                  style: TextStyle(color: textSecondary, fontSize: 14)),
            ],
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: textSecondary, size: 20),
          items: kLocations
              .map(
                (loc) => DropdownMenuItem<LocationModel>(
                  value: loc,
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.uitBlue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.name,
                          style: TextStyle(color: textPrimary, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
