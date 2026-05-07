import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uithelp/core/themes/app_theme.dart';
import 'package:uithelp/features/viewmodels/locket_viewmodel.dart';
import 'package:uithelp/features/views/home/widgets/locket_card.dart';
import 'package:uithelp/features/views/home/widgets/create_locket_sheet.dart';

class LocketPage extends StatefulWidget {
  const LocketPage({super.key});

  @override
  State<LocketPage> createState() => _LocketPageState();
}

class _LocketPageState extends State<LocketPage> {
  late final PageController _pageCtrl;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.82);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocketViewModel>().loadLockets(refresh: true);
    });
    _pageCtrl.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    final page = _pageCtrl.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() => _currentPage = page);
    }
    // Load more khi gần cuối
    final vm = context.read<LocketViewModel>();
    if (page >= vm.lockets.length - 2) {
      vm.loadLockets();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _openCreate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateLocketSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vm = context.watch<LocketViewModel>();
    final bg = isDark ? AppColors.darkBackground : const Color(0xFFEEF2F7);

    return Container(
      color: bg,
      child: Column(
        children: [
          // ── Feed ──────────────────────────────────────────────────────────
          Expanded(
            child: vm.isLoading && vm.lockets.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.uitBlue,
                      strokeWidth: 2.5,
                    ),
                  )
                : vm.lockets.isEmpty
                    ? _buildEmpty(isDark)
                    : RefreshIndicator(
                        color: AppColors.uitBlue,
                        onRefresh: () =>
                            context.read<LocketViewModel>().loadLockets(refresh: true),
                        child: _buildSwipeFeed(vm, isDark),
                      ),
          ),

          // ── Camera button ─────────────────────────────────────────────────
          _CameraBar(onTap: _openCreate, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildSwipeFeed(LocketViewModel vm, bool isDark) {
    return Column(
      children: [
        // Dot indicators
        if (vm.lockets.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: _DotIndicator(
              count: vm.lockets.length,
              current: _currentPage,
            ),
          )
        else
          const SizedBox(height: 12),

        // PageView cards
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: vm.lockets.length,
            itemBuilder: (_, i) {
              final isActive = i == _currentPage;
              return AnimatedScale(
                scale: isActive ? 1.0 : 0.91,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: LocketCard(
                  locket: vm.lockets[i],
                  isActive: isActive,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.uitBlue.withOpacity(0.1),
            ),
            child: const Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.uitBlue),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có locket nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF050505),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hãy là người đầu tiên chia sẻ khoảnh khắc',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ── DOT INDICATOR ─────────────────────────────────────────────────────────────
class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _DotIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    final visible = count > 20 ? 20 : count;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(visible, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.uitBlue : Colors.grey.withOpacity(0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ── CAMERA BAR ────────────────────────────────────────────────────────────────
class _CameraBar extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;
  const _CameraBar({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.uitBlue,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.uitBlue.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
