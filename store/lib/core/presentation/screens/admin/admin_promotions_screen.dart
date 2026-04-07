import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../data/models/promotion_model.dart';
import '../../../data/repositories/promotion_repository.dart';

class AdminPromotionsScreen extends StatefulWidget {
  const AdminPromotionsScreen({super.key});

  @override
  State<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends State<AdminPromotionsScreen> {
  final PromotionRepository _repository = PromotionRepository();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  List<PromotionModel> _promotions = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final promotions = await _repository.getPromotions();
      if (!mounted) return;
      setState(() {
        _promotions = promotions;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Promotions'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadPromotions,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePromotionDialog,
        backgroundColor: const Color(0xFF2F6BFF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Promotion'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _promotions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _promotions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 42),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPromotions,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF2F6BFF), Color(0xFF6E9BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2F6BFF).withAlpha(75),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.campaign_outlined, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_promotions.length} promotions configured',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_promotions.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: Text('No promotions yet. Create your first campaign.')),
            ),
          ..._promotions.map((promotion) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          promotion.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: promotion.isActive
                              ? Colors.green.withAlpha(20)
                              : Colors.grey.withAlpha(20),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          promotion.isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: promotion.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Code: ${promotion.code} • ${promotion.discountValue} ${promotion.discountType == 'percent' ? '%' : 'off'}'),
                  const SizedBox(height: 4),
                  Text(
                    'Valid: ${_dateFormat.format(promotion.startsAt)} - ${_dateFormat.format(promotion.endsAt)}',
                  ),
                  if ((promotion.description ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(promotion.description!),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Switch.adaptive(
                        value: promotion.isActive,
                        onChanged: (value) async {
                          await _repository.updatePromotionStatus(
                            promotionId: promotion.id,
                            isActive: value,
                          );
                          await _loadPromotions();
                        },
                      ),
                      const Text('Enabled'),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Generate QR',
                        onPressed: () => _showPromotionQrDialog(promotion),
                        icon: const Icon(Icons.qr_code_2_rounded),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () async {
                          await _repository.deletePromotion(promotion.id);
                          await _loadPromotions();
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
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
  }

  Future<void> _showCreatePromotionDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final codeController = TextEditingController();
    final descriptionController = TextEditingController();
    final discountController = TextEditingController();
    final minOrderController = TextEditingController(text: '0');

    String discountType = 'percent';
    DateTime startsAt = DateTime.now();
    DateTime endsAt = DateTime.now().add(const Duration(days: 7));

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Promotion'),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(labelText: 'Title'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: codeController,
                          decoration: const InputDecoration(labelText: 'Code'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: discountType,
                          decoration: const InputDecoration(labelText: 'Discount Type'),
                          items: const [
                            DropdownMenuItem(value: 'percent', child: Text('Percent (%)')),
                            DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                discountType = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: discountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Discount Value'),
                          validator: (value) {
                            final parsed = double.tryParse(value ?? '');
                            if (parsed == null || parsed <= 0) return 'Invalid discount';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: minOrderController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Minimum Order Amount'),
                          validator: (value) {
                            final parsed = double.tryParse(value ?? '');
                            if (parsed == null || parsed < 0) return 'Invalid amount';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Description (optional)'),
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Starts'),
                          subtitle: Text(_dateFormat.format(startsAt)),
                          trailing: const Icon(Icons.date_range_outlined),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startsAt,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                startsAt = picked;
                                if (endsAt.isBefore(startsAt)) {
                                  endsAt = startsAt.add(const Duration(days: 1));
                                }
                              });
                            }
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Ends'),
                          subtitle: Text(_dateFormat.format(endsAt)),
                          trailing: const Icon(Icons.date_range_outlined),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endsAt,
                              firstDate: startsAt,
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                endsAt = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    await _repository.createPromotion(
                      title: titleController.text.trim(),
                      code: codeController.text.trim().toUpperCase(),
                      description: descriptionController.text.trim(),
                      discountType: discountType,
                      discountValue: double.parse(discountController.text.trim()),
                      minOrderAmount: double.parse(minOrderController.text.trim()),
                      startsAt: startsAt,
                      endsAt: endsAt,
                    );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    codeController.dispose();
    descriptionController.dispose();
    discountController.dispose();
    minOrderController.dispose();

    if (created == true) {
      await _loadPromotions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promotion created successfully')),
      );
    }
  }

  Future<void> _showPromotionQrDialog(PromotionModel promotion) async {
    final payload = _buildQrPayload(promotion.code);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Promotion QR Code'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  promotion.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  'Code: ${promotion.code}',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: payload));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('QR payload copied')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy Payload'),
            ),
          ],
        );
      },
    );
  }

  String _buildQrPayload(String code) {
    return 'PROMO:${code.trim().toUpperCase()}';
  }
}
