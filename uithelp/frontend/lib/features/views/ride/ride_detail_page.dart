import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../data/models/ride_model.dart';
import '../../../features/viewmodels/ride_viewmodel.dart';
import '../../../features/viewmodels/auth_viewmodel.dart';
import '../../../features/viewmodels/conversation_viewmodel.dart';
import '../chat/message_page.dart';
import 'widgets/ride_card.dart';

class RideDetailPage extends StatefulWidget {
  final String rideId;
  const RideDetailPage({super.key, required this.rideId});

  @override
  State<RideDetailPage> createState() => _RideDetailPageState();
}

class _RideDetailPageState extends State<RideDetailPage> {
  final _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<RideViewModel>();
      vm.loadRideDetail(widget.rideId);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Chi tiết chuyến đi',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Consumer<RideViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoadingDetail) {
            return const Center(child: CircularProgressIndicator(color: AppColors.uitBlue));
          }
          final ride = vm.currentRide;
          if (ride == null) {
            return const Center(child: Text('Không tìm thấy chuyến đi'));
          }
          final myId = context.read<AuthViewModel>().currentUser?.id ?? '';
          final isOwner = ride.userId == myId;

          return RefreshIndicator(
            color: AppColors.uitBlue,
            onRefresh: () => vm.loadRideDetail(ride.id),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                _RideInfoCard(ride: ride, isDark: isDark),
                _OwnerCard(ride: ride, isDark: isDark),
                if (ride.participants.isNotEmpty)
                  _ParticipantsSection(ride: ride, isDark: isDark),
                if (isOwner && ride.isActive)
                  _RequestsSection(
                    rideId: ride.id,
                    isDark: isDark,
                    onLoad: () => vm.loadRideRequests(ride.id),
                    requests: vm.rideRequests,
                    onAccept: (reqId) => vm.acceptRequest(reqId, ride.id),
                    onReject: (reqId) => vm.rejectRequest(reqId, ride.id),
                  ),
                if (vm.matchedRides.isNotEmpty)
                  _MatchedSection(rides: vm.matchedRides, isDark: isDark),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<RideViewModel>(
        builder: (context, vm, _) {
          final ride = vm.currentRide;
          if (ride == null) return const SizedBox.shrink();
          final myId = context.read<AuthViewModel>().currentUser?.id ?? '';
          final isOwner = ride.userId == myId;
          return _BottomActions(
            ride: ride,
            isOwner: isOwner,
            myRequest: vm.myRequestFor(ride.id),
            isSending: vm.isSendingRequest,
            onJoin: () => _showJoinDialog(context, ride),
            onCancel: (reqId) => vm.cancelRideRequest(reqId, ride.id),
            onChat: () => _openChat(context, ride),
            onComplete: () => _confirmComplete(context, vm, ride.id),
            onCancelRide: () => _confirmCancelRide(context, vm, ride.id),
          );
        },
      ),
    );
  }

  void _showJoinDialog(BuildContext context, RideModel ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JoinSheet(
        rideId: ride.id,
        msgCtrl: _msgCtrl,
        onSend: (msg) async {
          final ok = await context.read<RideViewModel>().requestJoinRide(ride.id, message: msg);
          if (!context.mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok ? 'Đã gửi! Chờ bạn ấy xác nhận nhé 🙌' : context.read<RideViewModel>().errorMessage ?? 'Lỗi'),
            backgroundColor: ok ? AppColors.success : AppColors.error,
          ));
        },
      ),
    );
  }

  Future<void> _openChat(BuildContext context, RideModel ride) async {
    final convVm = context.read<ConversationViewModel>();
    final conv = await convVm.getOrCreate(ride.userId);
    if (!context.mounted || conv == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MessagePage(conversation: conv, otherUserName: ride.userName),
    ));
  }

  void _confirmComplete(BuildContext context, RideViewModel vm, String rideId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hoàn thành chuyến đi?'),
        content: const Text('Xác nhận chuyến đi đã hoàn thành.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await vm.completeRide(rideId);
            },
            child: const Text('Xác nhận', style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
  }

  void _confirmCancelRide(BuildContext context, RideViewModel vm, String rideId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hủy chuyến đi?'),
        content: const Text('Tất cả yêu cầu đang chờ sẽ bị từ chối.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Không')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await vm.cancelRide(rideId);
            },
            child: const Text('Hủy chuyến', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Ride Info Card ────────────────────────────────────────────────────────────
class _RideInfoCard extends StatelessWidget {
  final RideModel ride;
  final bool isDark;
  const _RideInfoCard({required this.ride, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: isDark ? AppColors.darkCardShadow : AppColors.lightCardShadow, blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TypeBadgeLarge(type: ride.type),
              const Spacer(),
              _StatusBadge(status: ride.status),
            ],
          ),
          const SizedBox(height: 20),
          // Route visual
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.uitBlue, shape: BoxShape.circle)),
                  Container(width: 2, height: 36, color: AppColors.uitBlue.withOpacity(0.3)),
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Điểm đi', style: TextStyle(fontSize: 11, color: textSecondary)),
                    Text(ride.from.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 20),
                    Text('Điểm đến', style: TextStyle(fontSize: 11, color: textSecondary)),
                    Text(ride.to.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.access_time_rounded, label: 'Khởi hành', value: _fmtDt(ride.departureTime), color: AppColors.uitBlue),
          if (ride.contact.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.phone_rounded, label: 'Liên hệ', value: ride.contact, color: AppColors.success),
          ],
          if (ride.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Mô tả', style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(ride.description, style: TextStyle(fontSize: 14, color: textPrimary, height: 1.5)),
          ],
        ],
      ),
    );
  }

  String _fmtDt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$h:$m  •  $d/$mo/${dt.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          ],
        ),
      ],
    );
  }
}

class _TypeBadgeLarge extends StatelessWidget {
  final String type;
  const _TypeBadgeLarge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isFind = type == 'find';
    final color = isFind ? AppColors.uitBlue : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isFind ? Icons.search_rounded : Icons.directions_bike_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Text(isFind ? 'Tìm bạn đi' : 'Rủ đi cùng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'full': color = AppColors.warning; label = 'Đã đầy'; break;
      case 'done': color = AppColors.lightTextSecondary; label = 'Hoàn thành'; break;
      case 'cancelled': color = AppColors.error; label = 'Đã hủy'; break;
      default: color = AppColors.success; label = 'Còn chỗ';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ── Owner Card ────────────────────────────────────────────────────────────────
class _OwnerCard extends StatelessWidget {
  final RideModel ride;
  final bool isDark;
  const _OwnerCard({required this.ride, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: isDark ? AppColors.darkCardShadow : AppColors.lightCardShadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.uitBlue, AppColors.slateBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                ride.userName.isNotEmpty ? ride.userName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ride.userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                const SizedBox(height: 2),
                Text('Người đăng lịch đi học', style: TextStyle(fontSize: 12, color: textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.uitBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 13, color: AppColors.uitBlue),
                SizedBox(width: 4),
                Text('UIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.uitBlue)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Participants Section ───────────────────────────────────────────────────────
class _ParticipantsSection extends StatelessWidget {
  final RideModel ride;
  final bool isDark;
  const _ParticipantsSection({required this.ride, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: isDark ? AppColors.darkCardShadow : AppColors.lightCardShadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_rounded, size: 18, color: AppColors.uitBlue),
              const SizedBox(width: 8),
              Text('Người tham gia (${ride.participants.length})',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          ...ride.participants.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(p.userName.isNotEmpty ? p.userName[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(p.userName, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary))),
                Text(_fmtJoined(p.joinedAt), style: TextStyle(fontSize: 11, color: textSecondary)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _fmtJoined(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return 'Tham gia $d/$m';
  }
}

// ── Requests Section (owner only) ─────────────────────────────────────────────
class _RequestsSection extends StatefulWidget {
  final String rideId;
  final bool isDark;
  final VoidCallback onLoad;
  final List<RideRequestModel> requests;
  final Future<bool> Function(String) onAccept;
  final Future<bool> Function(String) onReject;

  const _RequestsSection({
    required this.rideId,
    required this.isDark,
    required this.onLoad,
    required this.requests,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_RequestsSection> createState() => _RequestsSectionState();
}

class _RequestsSectionState extends State<_RequestsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLoad());
  }

  @override
  Widget build(BuildContext context) {
    final surface = widget.isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (widget.requests.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: widget.isDark ? AppColors.darkCardShadow : AppColors.lightCardShadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inbox_rounded, size: 18, color: AppColors.warning),
              const SizedBox(width: 8),
              Text('Yêu cầu tham gia (${widget.requests.length})',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.requests.map((req) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.darkBackground : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.uitBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text(req.userName.isNotEmpty ? req.userName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.uitBlue, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(req.userName, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary))),
                  ],
                ),
                if (req.message.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(req.message, style: TextStyle(fontSize: 13, color: textSecondary)),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onReject(req.id),
                        child: Container(
                          height: 34,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.error.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(child: Text('Từ chối', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onAccept(req.id),
                        child: Container(
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.uitBlue, AppColors.slateBlue]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(child: Text('Chấp nhận', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── Matched Section ───────────────────────────────────────────────────────────
class _MatchedSection extends StatelessWidget {
  final List<RideModel> rides;
  final bool isDark;
  const _MatchedSection({required this.rides, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: isDark ? AppColors.darkCardShadow : AppColors.lightCardShadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.uitBlue, AppColors.slateBlue]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Phù hợp cao', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Text('Chuyến đi tương thích', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          ...rides.take(3).map((r) => RideCard(ride: r)),
        ],
      ),
    );
  }
}

// ── Bottom Actions ────────────────────────────────────────────────────────────
class _BottomActions extends StatelessWidget {
  final RideModel ride;
  final bool isOwner;
  final RideRequestModel? myRequest;
  final bool isSending;
  final VoidCallback onJoin;
  final Future<bool> Function(String) onCancel;
  final VoidCallback onChat;
  final VoidCallback onComplete;
  final VoidCallback onCancelRide;

  const _BottomActions({
    required this.ride,
    required this.isOwner,
    required this.myRequest,
    required this.isSending,
    required this.onJoin,
    required this.onCancel,
    required this.onChat,
    required this.onComplete,
    required this.onCancelRide,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      color: surface,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      child: Row(
        children: [
          // Chat button (always visible unless owner)
          if (!isOwner) ...[
            GestureDetector(
              onTap: onChat,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.uitBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.chat_bubble_rounded, color: AppColors.uitBlue, size: 22),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(child: _mainButton(context)),
        ],
      ),
    );
  }

  Widget _mainButton(BuildContext context) {
    // Owner actions
    if (isOwner) {
      if (ride.isActive || ride.isFull) {
        return Row(
          children: [
            Expanded(
              child: _Btn(
                label: 'Hoàn thành',
                color: AppColors.success,
                onTap: onComplete,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Btn(
                label: 'Hủy chuyến',
                color: AppColors.error,
                outlined: true,
                onTap: onCancelRide,
              ),
            ),
          ],
        );
      }
      return const SizedBox.shrink();
    }

    // Participant: already joined
    final isParticipant = ride.participants.any(
      (p) => p.userId == context.read<AuthViewModel>().currentUser?.id,
    );
    if (isParticipant) {
      return _Btn(label: 'Đã tham gia ✓', color: AppColors.success, onTap: () {});
    }

    // Ride ended
    if (ride.isDone || ride.isCancelled) {
      return _Btn(label: ride.isDone ? 'Đã hoàn thành' : 'Đã hủy', color: Colors.grey, onTap: () {});
    }

    // Has pending request
    if (myRequest != null) {
      if (myRequest!.isPending) {
        return _Btn(
          label: 'Đang chờ xác nhận  •  Hủy',
          color: AppColors.warning,
          outlined: true,
          onTap: () => onCancel(myRequest!.id),
        );
      }
      if (myRequest!.isAccepted) {
        return _Btn(label: 'Đã được chấp nhận ✓', color: AppColors.success, onTap: () {});
      }
      if (myRequest!.isRejected) {
        return _Btn(label: 'Yêu cầu bị từ chối', color: AppColors.error, outlined: true, onTap: () {});
      }
    }

    // Full
    if (ride.isFull) {
      return _Btn(label: 'Đã đầy', color: Colors.grey, onTap: () {});
    }

    // Default: send request
    return _Btn(
      label: isSending ? 'Đang gửi...' : 'Xin đi học cùng',
      color: AppColors.uitBlue,
      gradient: true,
      onTap: isSending ? () {} : onJoin,
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final bool gradient;
  final VoidCallback onTap;

  const _Btn({
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: gradient ? const LinearGradient(colors: [AppColors.uitBlue, AppColors.slateBlue]) : null,
          color: gradient ? null : (outlined ? Colors.transparent : color.withOpacity(0.12)),
          borderRadius: BorderRadius.circular(14),
          border: outlined ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: gradient ? Colors.white : color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Join Sheet ────────────────────────────────────────────────────────────────
class _JoinSheet extends StatelessWidget {
  final String rideId;
  final TextEditingController msgCtrl;
  final Future<void> Function(String) onSend;

  const _JoinSheet({required this.rideId, required this.msgCtrl, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final inputFill = isDark ? AppColors.darkInputFill : AppColors.lightInputFill;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Text('Xin tham gia đi học cùng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 6),
          Text('Nhắn gì đó cho bạn ấy (tuỳ chọn)', style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          const SizedBox(height: 16),
          TextField(
            controller: msgCtrl,
            maxLines: 3,
            autofocus: true,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'Ví dụ: Mình ở KTX Khu A, mình đi cùng được không?',
              hintStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13),
              filled: true,
              fillColor: inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => onSend(msgCtrl.text.trim()),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.uitBlue, AppColors.slateBlue]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('Xin đi cùng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
