import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uithelp/core/themes/app_theme.dart';
import 'package:uithelp/features/viewmodels/locket_viewmodel.dart';
import 'package:uithelp/features/views/home/widgets/locket_card.dart';
import 'package:uithelp/features/views/home/widgets/create_locket_sheet.dart';

class MyLocketPage extends StatefulWidget {
  const MyLocketPage({super.key});

  @override
  State<MyLocketPage> createState() => _MyLocketPageState();
}

class _MyLocketPageState extends State<MyLocketPage> {
  late final PageController _pageCtrl;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.82);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocketViewModel>().loadMyLockets(refresh: true);
    });
    _pageCtrl.addListener(() {
      final page = _pageCtrl.page?.round() ?? 0;
      if (page != _currentPage) setState(() => _currentPage = page);
      final vm = context.read<LocketViewModel>();
      if (page >= vm.myLockets.length - 2) vm.loadMyLockets();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vm = context.watch<LocketViewModel>();

    return Column(
      children: [
        Expanded(
          child: vm.isLoadingMy && vm.myLockets.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : vm.myLockets.isEmpty
                  ? _buildEmpty(isDark)
                  : RefreshIndicator(
                      onRefresh: () =>
                          context.read<LocketViewModel>().loadMyLockets(refresh: true),
                      child: Column(
                        children: [
                          if (vm.myLockets.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 4),
                              child: _MyDotIndicator(
                                count: vm.myLockets.length,
                                current: _currentPage,
                              ),
                            )
                          else
                            const SizedBox(height: 12),
                          Expanded(
                            child: PageView.builder(
                              controller: _pageCtrl,
                              itemCount: vm.myLockets.length,
                              itemBuilder: (_, i) {
                                final isActive = i == _currentPage;
                                return AnimatedScale(
                                  scale: isActive ? 1.0 : 0.91,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  child: LocketCard(
                                    locket: vm.myLockets[i],
                                    isActive: isActive,
                                    showActions: true,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
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
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B6B).withOpacity(0.15),
                  const Color(0xFFFF8E53).withOpacity(0.15),
                ],
              ),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              size: 40,
              color: Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bạn chưa có locket nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF050505),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chia sẻ khoảnh khắc của bạn với bạn bè',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _openCreateLocket(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Tạo locket đầu tiên',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateLocket(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateLocketSheet(),
    );
  }
}

class _MyDotIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _MyDotIndicator({required this.count, required this.current});

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
            color: active
                ? const Color(0xFF2563EB)
                : Colors.grey.withOpacity(0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
