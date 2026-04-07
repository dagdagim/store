import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../../services/local_storage_service.dart';
import 'admin_products_screen.dart';

int _safeNonNegativeInt(dynamic value) {
  if (value is int) {
    return value < 0 ? 0 : value;
  }

  if (value is num) {
    if (!value.isFinite) {
      return 0;
    }
    final parsed = value.toInt();
    return parsed < 0 ? 0 : parsed;
  }

  if (value is String) {
    final parsed = num.tryParse(value);
    if (parsed == null || !parsed.isFinite) {
      return 0;
    }
    final asInt = parsed.toInt();
    return asInt < 0 ? 0 : asInt;
  }

  return 0;
}

class _InventoryTrendPoint {
  final DateTime time;
  final int lowStockCount;
  final int outOfStockCount;
  final int inventoryUnits;

  _InventoryTrendPoint({
    required this.time,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.inventoryUnits,
  });

  factory _InventoryTrendPoint.fromJson(Map<String, dynamic> json) {
    final rawTime = json['t']?.toString();
    final parsedTime = DateTime.tryParse(rawTime ?? '') ?? DateTime.now();

    return _InventoryTrendPoint(
      time: parsedTime,
      lowStockCount: _safeNonNegativeInt(json['low']),
      outOfStockCount: _safeNonNegativeInt(json['out']),
      inventoryUnits: _safeNonNegativeInt(json['units']),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ProductRepository _productRepository = ProductRepository();
  late Future<InventoryInsights> _insightsFuture;
  List<_InventoryTrendPoint> _trendPoints = [];
  Timer? _autoRefreshTimer;
  int _threshold = 5;
  int _auditRangeDays = 7;

  List<Map<String, dynamic>> _sortedAuditLogs() {
    final logs = LocalStorageService.getInventoryAuditLogs();
    logs.sort((a, b) {
      final at = DateTime.tryParse(a['t']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = DateTime.tryParse(b['t']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    return logs;
  }

  List<Map<String, dynamic>> _filteredAuditLogs() {
    final sorted = _sortedAuditLogs();
    if (_auditRangeDays == 0) {
      return sorted;
    }

    final now = DateTime.now();
    final threshold = now.subtract(Duration(days: _auditRangeDays));
    return sorted.where((entry) {
      final t = DateTime.tryParse(entry['t']?.toString() ?? '');
      if (t == null) {
        return false;
      }
      return t.isAfter(threshold);
    }).toList();
  }

  List<Map<String, dynamic>> _recentAuditLogs() {
    final logs = _filteredAuditLogs();
    return logs.take(5).toList();
  }

  String _auditRangeLabel() {
    switch (_auditRangeDays) {
      case 1:
        return 'today';
      case 7:
        return '7d';
      case 30:
        return '30d';
      default:
        return 'all';
    }
  }

  String _formatAuditTimestamp(String? iso) {
    final t = DateTime.tryParse(iso ?? '');
    if (t == null) {
      return '--';
    }

    final month = t.month.toString().padLeft(2, '0');
    final day = t.day.toString().padLeft(2, '0');
    final hour = t.hour.toString().padLeft(2, '0');
    final min = t.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$min';
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'single_restock':
        return 'Single Restock';
      case 'bulk_restock':
        return 'Bulk Restock';
      case 'undo_bulk_restock':
        return 'Undo Bulk';
      default:
        return action;
    }
  }

  @override
  void initState() {
    super.initState();
    _reloadTrendFromStorage();
    _insightsFuture = _loadInsightsAndRecordTrend();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) {
        return;
      }
      _refreshInsights();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _refreshInsights() {
    setState(() {
      _insightsFuture = _loadInsightsAndRecordTrend();
    });
  }

  Future<InventoryInsights> _loadInsightsAndRecordTrend() async {
    final insights = await _productRepository.getInventoryInsights(
      threshold: _threshold,
    );
    await LocalStorageService.addInventoryTrendSnapshot(
      lowStockCount: insights.lowStockCount,
      outOfStockCount: insights.outOfStockCount,
      inventoryUnits: insights.inventoryUnits,
      threshold: _threshold,
    );
    _reloadTrendFromStorage();
    return insights;
  }

  void _reloadTrendFromStorage({bool notify = true}) {
    final snapshots = LocalStorageService.getInventoryTrendSnapshots(
      threshold: _threshold,
    );
    final points = snapshots.map(_InventoryTrendPoint.fromJson).toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    if (!mounted || !notify) {
      _trendPoints = points;
      return;
    }

    setState(() {
      _trendPoints = points;
    });
  }

  void _setThreshold(int value) {
    if (_threshold == value) {
      return;
    }

    _threshold = value;
    _reloadTrendFromStorage(notify: false);

    setState(() {
      _insightsFuture = _loadInsightsAndRecordTrend();
    });
  }

  Future<void> _exportInventoryReport() async {
    try {
      final insights = await _productRepository.getInventoryInsights(
        threshold: _threshold,
      );
      final trend = LocalStorageService.getInventoryTrendSnapshots(
        threshold: _threshold,
      );

      final payload = {
        'generatedAt': DateTime.now().toIso8601String(),
        'threshold': _threshold,
        'totals': {
          'totalProducts': insights.totalProducts,
          'activeProducts': insights.activeProducts,
          'lowStockCount': insights.lowStockCount,
          'outOfStockCount': insights.outOfStockCount,
          'inventoryUnits': insights.inventoryUnits,
        },
        'categoryBreakdown': insights.categoryBreakdown
            .map(
              (item) => {
                'category': item.category,
                'lowStock': item.lowStock,
                'outOfStock': item.outOfStock,
                'suggestedReorderTotal': item.suggestedReorderTotal,
              },
            )
            .toList(),
        'urgentProducts': insights.urgentProducts
            .map(
              (item) => {
                'id': item.id,
                'name': item.name,
                'category': item.category,
                'totalStock': item.totalStock,
                'isAvailable': item.isAvailable,
                'suggestedReorderQty': item.suggestedReorderQty,
              },
            )
            .toList(),
        'trendSnapshots': trend,
      };

      const encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(payload);

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Inventory Report Export'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: SelectableText(
                  prettyJson,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: prettyJson));
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Report JSON copied to clipboard'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_all_rounded),
                label: const Text('Copy JSON'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export inventory report')),
      );
    }
  }

  Future<void> _openLowStockView({
    String? initialCategoryFocus,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminProductsScreen(
          initialLowStockOnly: true,
          initialCategoryFocus: initialCategoryFocus,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    _refreshInsights();
  }

  Future<void> _exportAuditLogsOnly() async {
    try {
      final logs = _filteredAuditLogs();

      final payload = {
        'generatedAt': DateTime.now().toIso8601String(),
        'range': _auditRangeLabel(),
        'logCount': logs.length,
        'logs': logs,
      };

      const encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(payload);

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Audit Log Export'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: SelectableText(
                  prettyJson,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: prettyJson));
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Audit log JSON copied')),
                  );
                },
                icon: const Icon(Icons.copy_all_rounded),
                label: const Text('Copy JSON'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export audit log')),
      );
    }
  }

  Future<void> _clearAuditLogs() async {
    final filteredCount = _filteredAuditLogs().length;
    if (filteredCount == 0) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audit logs to clear for this filter')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Audit Log'),
          content: Text(
            'Remove all inventory audit entries?\nCurrent filter has $filteredCount item(s).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await LocalStorageService.clearInventoryAuditLogs();
    if (!mounted) {
      return;
    }

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audit log cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: const Center(child: Text('Admin access required')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Export inventory report',
            onPressed: _exportInventoryReport,
            icon: const Icon(Icons.file_download_outlined),
          ),
          IconButton(
            tooltip: 'Refresh analytics',
            onPressed: _refreshInsights,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF2F6BFF), Color(0xFF6E9BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2F6BFF).withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.space_dashboard_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Welcome Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${auth.user?.name ?? 'Admin'} • ${auth.user?.email ?? ''}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                FutureBuilder<InventoryInsights>(
                  future: _insightsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeroChip(label: 'Inventory', value: '...'),
                          _HeroChip(label: 'Low Stock', value: '...'),
                          _HeroChip(label: 'Out', value: '...'),
                        ],
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeroChip(label: 'Inventory', value: 'N/A'),
                          _HeroChip(label: 'Low Stock', value: 'N/A'),
                          _HeroChip(label: 'Out', value: 'N/A'),
                        ],
                      );
                    }

                    final insights = snapshot.data!;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroChip(label: 'Inventory', value: '${insights.inventoryUnits}u'),
                        _HeroChip(label: 'Low Stock', value: '${insights.lowStockCount}'),
                        _HeroChip(label: 'Out', value: '${insights.outOfStockCount}'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildInventoryPulseCard(),
          const SizedBox(height: 16),
          _moduleCard(
            context,
            title: 'Orders',
            subtitle: 'List and update order states',
            icon: Icons.receipt_long_outlined,
            routeName: '/admin/orders',
          ),
          _moduleCard(
            context,
            title: 'Products',
            subtitle: 'Add, edit, delete products',
            icon: Icons.inventory_2_outlined,
            routeName: '/admin/products',
          ),
          _moduleCard(
            context,
            title: 'Low Stock Alerts',
            subtitle: 'Review items that need restocking',
            icon: Icons.warning_amber_rounded,
            routeName: '/admin/products',
            onTap: () async {
              await _openLowStockView();
            },
          ),
          _moduleCard(
            context,
            title: 'Add Admin / Manage Users',
            subtitle: 'Create admins, manage user roles',
            icon: Icons.groups_2_outlined,
            routeName: '/admin/users',
          ),
          _moduleCard(
            context,
            title: 'Manage Category',
            subtitle: 'Category management tools',
            icon: Icons.category_outlined,
            routeName: '/admin/categories',
          ),
          _moduleCard(
            context,
            title: 'Reviews & Ratings',
            subtitle: 'View customer feedback and ratings',
            icon: Icons.reviews_outlined,
            routeName: '/admin/reviews',
          ),
          _moduleCard(
            context,
            title: 'Promotions',
            subtitle: 'Promotion and discount controls',
            icon: Icons.campaign_outlined,
            routeName: '/admin/promotions',
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryPulseCard() {
    return FutureBuilder<InventoryInsights>(
      future: _insightsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _pulseSkeleton();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inventory Pulse',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text('Unable to load stock analytics right now.'),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _refreshInsights,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final insights = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inventory Pulse',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Threshold',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  ChoiceChip(
                    label: const Text('3'),
                    selected: _threshold == 3,
                    onSelected: (_) => _setThreshold(3),
                  ),
                  ChoiceChip(
                    label: const Text('5'),
                    selected: _threshold == 5,
                    onSelected: (_) => _setThreshold(5),
                  ),
                  ChoiceChip(
                    label: const Text('10'),
                    selected: _threshold == 10,
                    onSelected: (_) => _setThreshold(10),
                  ),
                  Text(
                    '(active: ${insights.threshold})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _metricPill('Total Products', '${insights.totalProducts}', const Color(0xFFEFF4FF), const Color(0xFF2F6BFF)),
                  _metricPill('Active', '${insights.activeProducts}', const Color(0xFFEAFBF0), const Color(0xFF1F9D57)),
                  _metricPill('Low Stock', '${insights.lowStockCount}', const Color(0xFFFFF5E8), const Color(0xFFD97706)),
                  _metricPill('Out of Stock', '${insights.outOfStockCount}', const Color(0xFFFFECEC), const Color(0xFFDC2626)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Category Reorder Recommendations',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (insights.categoryBreakdown.isEmpty)
                const Text('No category-level recommendations right now.')
              else
                ...insights.categoryBreakdown.take(4).map((entry) {
                  final riskScore = entry.lowStock + entry.outOfStock;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.category.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(20),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Risk $riskScore',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2F6BFF).withAlpha(20),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Reorder +${entry.suggestedReorderTotal}',
                            style: const TextStyle(
                              color: Color(0xFF2F6BFF),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _openLowStockView(
                              initialCategoryFocus: entry.category,
                            );
                          },
                          child: const Text('Focus'),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 12),
              _buildTrendStrip(),
              const SizedBox(height: 12),
              const Text(
                'Recent Inventory Actions',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Today'),
                    selected: _auditRangeDays == 1,
                    onSelected: (_) {
                      setState(() {
                        _auditRangeDays = 1;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('7d'),
                    selected: _auditRangeDays == 7,
                    onSelected: (_) {
                      setState(() {
                        _auditRangeDays = 7;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('30d'),
                    selected: _auditRangeDays == 30,
                    onSelected: (_) {
                      setState(() {
                        _auditRangeDays = 30;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _auditRangeDays == 0,
                    onSelected: (_) {
                      setState(() {
                        _auditRangeDays = 0;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _filteredAuditLogs().isEmpty ? null : _exportAuditLogsOnly,
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text('Export Audit'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _clearAuditLogs,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                    label: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final logs = _recentAuditLogs();
                  if (logs.isEmpty) {
                    return const Text('No inventory actions logged yet.');
                  }

                  return Column(
                    children: logs.map((entry) {
                      final action = _actionLabel(entry['action']?.toString() ?? 'unknown');
                      final category = entry['category']?.toString();
                      final productName = entry['productName']?.toString();
                      final success = (entry['successCount'] ?? 0).toString();
                      final failed = (entry['failedCount'] ?? 0).toString();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                category != null && category.trim().isNotEmpty
                                    ? '$action • ${category.toUpperCase()}'
                                    : productName != null && productName.trim().isNotEmpty
                                        ? '$action • $productName'
                                        : action,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F9D57).withAlpha(20),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '+$success',
                                style: const TextStyle(
                                  color: Color(0xFF1F9D57),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626).withAlpha(20),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '-$failed',
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatAuditTimestamp(entry['t']?.toString()),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Urgent Restock Queue',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (insights.urgentProducts.isEmpty)
                const Text('No urgent products right now.')
              else
                ...insights.urgentProducts.take(5).map((item) {
                  final isOut = !item.isAvailable || item.totalStock <= 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.category.toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOut ? Colors.red.withAlpha(20) : Colors.orange.withAlpha(20),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isOut ? 'OUT' : '${item.totalStock} left',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isOut ? Colors.red : Colors.orange.shade900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2F6BFF).withAlpha(20),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Reorder +${item.suggestedReorderQty}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2F6BFF),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Open low stock view',
                          onPressed: () async {
                            await _openLowStockView();
                          },
                          icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    await _openLowStockView();
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open Low Stock View'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendStrip() {
    if (_trendPoints.length < 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Trend for this threshold will appear after a few refreshes.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    final points = _trendPoints;
    final lowValues = points.map((item) => item.lowStockCount).toList();
    final outValues = points.map((item) => item.outOfStockCount).toList();

    final lowChange = lowValues.last - lowValues.first;
    final outChange = outValues.last - outValues.first;

    String trendLabel(int value) {
      if (value > 0) return '+$value';
      return '$value';
    }

    final maxLow = lowValues.reduce((a, b) => a > b ? a : b);
    final maxOut = outValues.reduce((a, b) => a > b ? a : b);
    final maxValue = (maxLow > maxOut ? maxLow : maxOut).clamp(1, 1000000);

    double heightFor(int value) {
      final ratio = value / maxValue;
      return 8 + (ratio * 26);
    }

    final tail = points.length > 8 ? points.sublist(points.length - 8) : points;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EAFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Stock Trend',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                'T$_threshold: Low ${trendLabel(lowChange)} • Out ${trendLabel(outChange)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: tail.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 10,
                        height: heightFor(item.outOfStockCount),
                        decoration: BoxDecoration(
                          color: Colors.red.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 10,
                        height: heightFor(item.lowStockCount),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              _LegendDot(color: Colors.orange),
              SizedBox(width: 4),
              Text('Low Stock', style: TextStyle(fontSize: 11)),
              SizedBox(width: 10),
              _LegendDot(color: Colors.red),
              SizedBox(width: 4),
              Text('Out of Stock', style: TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pulseSkeleton() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Pulse',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(minHeight: 6),
        ],
      ),
    );
  }

  Widget _metricPill(String label, String value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _moduleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String routeName,
    VoidCallback? onTap,
  }) {
    final badge = title == 'Promotions'
        ? 'Planned'
      : title == 'Reviews & Ratings'
        ? 'Live'
        : title == 'Manage Category'
            ? 'Basic'
            : 'Live';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap ?? () => Navigator.of(context).pushNamed(routeName),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2F6BFF).withAlpha(220),
                const Color(0xFF6E9BFF).withAlpha(200),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2F6BFF).withAlpha(15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Color(0xFF2F6BFF),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;
  final String value;

  const _HeroChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;

  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
