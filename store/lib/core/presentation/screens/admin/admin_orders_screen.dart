import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  static const List<String> _statuses = [
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'refunded',
  ];

  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (!auth.isAdmin) return;
      context.read<OrderProvider>().loadAllOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Orders')),
        body: const Center(child: Text('Admin access required')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Admin Orders'),
        actions: [
          IconButton(
            tooltip: 'Dashboard',
            onPressed: () => Navigator.of(context).pushNamed('/admin/dashboard'),
            icon: const Icon(Icons.dashboard_customize_outlined),
          ),
          IconButton(
            tooltip: 'Manage products',
            onPressed: () => Navigator.of(context).pushNamed('/admin/products'),
            icon: const Icon(Icons.inventory_2_outlined),
          ),
          PopupMenuButton<String?>(
            tooltip: 'Filter status',
            icon: const Icon(Icons.tune_rounded),
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
              context.read<OrderProvider>().loadAllOrders(status: value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String?>(value: null, child: Text('All Orders')),
              ..._statuses.map(
                (status) => PopupMenuItem<String?>(
                  value: status,
                  child: Text(status.toUpperCase()),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.adminOrders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.adminOrders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(provider.error!, textAlign: TextAlign.center),
              ),
            );
          }

          if (provider.adminOrders.isEmpty) {
            return Center(
              child: Text(
                _filterStatus == null
                    ? 'No orders found'
                    : 'No ${_filterStatus!.toUpperCase()} orders',
              ),
            );
          }

          final totalOrders = provider.adminOrders.length;
          final pendingCount = provider.adminOrders
              .where((order) => order.status.toLowerCase() == 'pending')
              .length;
          final deliveredCount = provider.adminOrders
              .where((order) => order.status.toLowerCase() == 'delivered')
              .length;
          final revenue = provider.adminOrders.fold<double>(
            0,
            (sum, order) => sum + order.totalPrice,
          );

          return RefreshIndicator(
            onRefresh: () => provider.loadAllOrders(status: _filterStatus),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withAlpha(12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF2F6BFF).withAlpha(20),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Color(0xFF2F6BFF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.user?.name ?? 'Admin',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              auth.user?.email ?? 'admin@medichain.com',
                              style: TextStyle(
                                color: Colors.black.withAlpha(150),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _badge('ROLE: ADMIN', Icons.verified_user_outlined),
                                _badge('FULL ACCESS', Icons.lock_open_rounded),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh orders',
                        onPressed: () => provider.loadAllOrders(status: _filterStatus),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2F6BFF), Color(0xFF6E9BFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2F6BFF).withAlpha(70),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Orders Overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _filterStatus == null
                            ? 'All order statuses'
                            : 'Filtered: ${_filterStatus!.toUpperCase()}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _statChip('Total', '$totalOrders', Icons.receipt_long),
                          _statChip('Pending', '$pendingCount', Icons.timelapse),
                          _statChip('Delivered', '$deliveredCount', Icons.task_alt),
                          _statChip(
                            'Revenue',
                            '${AppConstants.currency}${revenue.toStringAsFixed(0)}',
                            Icons.payments_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ...provider.adminOrders.map((order) {
                  final statusValue = _statuses.contains(order.status.toLowerCase())
                      ? order.status.toLowerCase()
                      : 'pending';
                  final isUpdating = provider.isOrderUpdating(order.id);
                  final idPreview =
                      order.id.substring(0, order.id.length > 8 ? 8 : order.id.length);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withAlpha(12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Order #$idPreview',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(statusValue).withAlpha(28),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                statusValue.toUpperCase(),
                                style: TextStyle(
                                  color: _statusColor(statusValue),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.customerName != null
                              ? '${order.customerName} • ${order.customerEmail ?? 'No email'}'
                              : 'Customer info unavailable',
                          style: TextStyle(
                            color: Colors.black.withAlpha(160),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _infoBadge(
                                icon: Icons.inventory_2_outlined,
                                text: '${order.items.length} items',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _infoBadge(
                                icon: Icons.payments_outlined,
                                text:
                                    '${AppConstants.currency}${order.totalPrice.toStringAsFixed(2)}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              'Update status',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (isUpdating) ...[
                              const SizedBox(width: 10),
                              const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black.withAlpha(20)),
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey.shade50,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: statusValue,
                                    isExpanded: true,
                                    items: _statuses
                                        .map(
                                          (status) => DropdownMenuItem<String>(
                                            value: status,
                                            child: Text(status.toUpperCase()),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: isUpdating ? null : (newStatus) async {
                                      if (newStatus == null || newStatus == statusValue) {
                                        return;
                                      }
                                      final ok = await context
                                          .read<OrderProvider>()
                                          .changeOrderStatus(
                                            orderId: order.id,
                                            status: newStatus,
                                          );
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            ok
                                                ? 'Order status updated to ${newStatus.toUpperCase()}'
                                                : 'Failed to update order status',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2F6BFF).withAlpha(16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2F6BFF)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2F6BFF),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'processing':
        return const Color(0xFF3B82F6);
      case 'shipped':
        return const Color(0xFF6366F1);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'refunded':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }
}
