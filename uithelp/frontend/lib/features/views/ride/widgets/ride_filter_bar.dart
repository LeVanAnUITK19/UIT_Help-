import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../data/models/ride_model.dart';

// Danh sách địa điểm UIT
const kLocations = [
  LocationModel(id: 'uit', name: 'UIT'),
  LocationModel(id: 'ktx_a', name: 'KTX Khu A'),
  LocationModel(id: 'ktx_b', name: 'KTX Khu B'),
];

class RideFilterBar extends StatefulWidget {
  final String? selectedType;
  final String? selectedFromId;
  final String? selectedToId;
  final void Function(String? type, String? fromId, String? toId) onFilter;

  const RideFilterBar({
    super.key,
    this.selectedType,
    this.selectedFromId,
    this.selectedToId,
    required this.onFilter,
  });

  @override
  State<RideFilterBar> createState() => _RideFilterBarState();
}

class _RideFilterBarState extends State<RideFilterBar> {
  String? _type;
  String? _fromId;
  String? _toId;

  @override
  void initState() {
    super.initState();
    _type = widget.selectedType;
    _fromId = widget.selectedFromId;
    _toId = widget.selectedToId;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final inputFill = isDark ? AppColors.darkInputFill : AppColors.lightInputFill;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Type toggle + Lọc button ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _TypeToggle(
                        label: 'Tất cả',
                        icon: Icons.list_rounded,
                        selected: _type == null,
                        onTap: () => setState(() => _type = null),
                      ),
                      const SizedBox(width: 6),
                      _TypeToggle(
                        label: 'Tìm bạn đi',
                        icon: Icons.search_rounded,
                        selected: _type == 'find',
                        onTap: () => setState(
                            () => _type = _type == 'find' ? null : 'find'),
                        color: AppColors.uitBlue,
                      ),
                      const SizedBox(width: 6),
                      _TypeToggle(
                        label: 'Rủ đi cùng',
                        icon: Icons.directions_bike_rounded,
                        selected: _type == 'offer',
                        onTap: () => setState(
                            () => _type = _type == 'offer' ? null : 'offer'),
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => widget.onFilter(_type, _fromId, _toId),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.uitBlue, AppColors.slateBlue],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Lọc',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Location filters ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _LocationDropdown(
                  hint: 'Từ',
                  value: _fromId,
                  fill: inputFill,
                  textSecondary: textSecondary,
                  onChanged: (v) => setState(() => _fromId = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 16, color: textSecondary),
              ),
              Expanded(
                child: _LocationDropdown(
                  hint: 'Đến',
                  value: _toId,
                  fill: inputFill,
                  textSecondary: textSecondary,
                  onChanged: (v) => setState(() => _toId = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _TypeToggle({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.color = AppColors.uitBlue,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? color : Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final Color fill;
  final Color textSecondary;
  final void Function(String?) onChanged;

  const _LocationDropdown({
    required this.hint,
    required this.value,
    required this.fill,
    required this.textSecondary,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint,
              style: TextStyle(fontSize: 12, color: textSecondary)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: textSecondary),
          style: TextStyle(fontSize: 12, color: textSecondary),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('Tất cả', style: TextStyle(color: textSecondary)),
            ),
            ...kLocations.map(
              (loc) => DropdownMenuItem<String>(
                value: loc.id,
                child: Text(
                  loc.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textSecondary),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
