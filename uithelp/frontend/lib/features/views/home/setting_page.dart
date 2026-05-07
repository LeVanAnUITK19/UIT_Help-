import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/token_storage.dart';
import '../../../core/themes/app_colors.dart';
import '../../../features/viewmodels/auth_viewmodel.dart';
import '../auth/login_page.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthViewModel>().currentUser;

    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFEAEEF6);
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final dividerColor = isDark ? AppColors.darkDivider : const Color(0xFFE2E8F0);

    String formatDate(DateTime? dt) {
      if (dt == null) return '—';
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header avatar + name ──────────────────────────────────────
            Container(
              width: double.infinity,
              color: bgColor,
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkDivider : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      color: cardColor,
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 40,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.name ?? '—',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Thông tin card ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black26
                          : Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Text(
                        'Thông tin',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Tên người dùng',
                      value: user?.name ?? '—',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      dividerColor: dividerColor,
                    ),
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user?.email ?? '—',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      dividerColor: dividerColor,
                    ),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Ngày tham gia',
                      value: formatDate(user?.createdAt),
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      dividerColor: dividerColor,
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Action buttons ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Đổi mật khẩu',
                    cardColor: cardColor,
                    textPrimary: textPrimary,
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.settings_outlined,
                    label: 'Cài đặt',
                    cardColor: cardColor,
                    textPrimary: textPrimary,
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.logout_rounded,
                    label: 'Đăng xuất',
                    cardColor: cardColor,
                    textPrimary: AppColors.error,
                    iconColor: AppColors.error,
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await TokenStorage().clearAll();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;
  final Color dividerColor;
  final bool showDivider;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
    required this.dividerColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: dividerColor, indent: 48),
      ],
    );
  }
}

// ── Action tile ───────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color cardColor;
  final Color textPrimary;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.cardColor,
    required this.textPrimary,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: color),
          ],
        ),
      ),
    );
  }
}
