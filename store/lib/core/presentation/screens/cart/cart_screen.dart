import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../providers/cart_provider.dart';
import '../checkout/checkout_screen.dart';
import '../../../constants/app_constants.dart';

const String _scannerFallbackToken = '__SCAN_FALLBACK__';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _promoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<CartProvider>(context, listen: false).loadCart();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, provider, _) {
              if (provider.items.isEmpty) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'Clear cart',
                onPressed: () => _confirmClearCart(context),
                icon: const Icon(Icons.delete_sweep_outlined),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(provider.error!, textAlign: TextAlign.center),
              ),
            );
          }

          if (provider.items.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  itemCount: provider.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = provider.items[index];
                    final availableStock = item.availableStock;
                    final hasStockInfo = availableStock != null;
                    final isLowStock = hasStockInfo && availableStock > 0 && availableStock <= 5;
                    final isAtMaxStock = hasStockInfo && item.quantity >= availableStock;
                    final isOverStock = hasStockInfo && item.quantity > availableStock;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 72,
                                height: 72,
                                color: Colors.grey.shade200,
                                child: item.image != null
                                    ? Image.network(
                                        item.image!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                            ),
                                      )
                                    : const Icon(
                                        Icons.image_not_supported_outlined,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.size != null && item.color != null
                                        ? '${item.size} • ${item.color}'
                                        : item.size ?? item.color ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  if (isOverStock)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Stock changed: only $availableStock left',
                                        style: TextStyle(
                                          color: Colors.red.shade900,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else if (isLowStock)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Only $availableStock left',
                                        style: TextStyle(
                                          color: Colors.orange.shade900,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: item.quantity > 1
                                            ? () => provider.updateQuantity(
                                                item.id,
                                                item.quantity - 1,
                                              )
                                            : null,
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                      ),
                                      Text('${item.quantity}'),
                                      IconButton(
                                        onPressed: isAtMaxStock
                                            ? null
                                            : () =>
                                                  provider.updateQuantity(
                                                    item.id,
                                                    item.quantity + 1,
                                                  ),
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      _confirmRemoveItem(context, item.id),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                Text(
                                  '${AppConstants.currency}${(item.price * item.quantity).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _promoController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Promotion code',
                        hintText: 'Enter code',
                        border: const OutlineInputBorder(),
                        prefixIcon: IconButton(
                          tooltip: 'Scan QR code',
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: provider.isApplyingPromotion
                              ? null
                              : () => _scanPromotionCode(context),
                        ),
                        suffixIcon: provider.isApplyingPromotion
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: provider.isApplyingPromotion
                                ? null
                                : () => _previewPromotion(context),
                            child: const Text('Preview'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: provider.isApplyingPromotion
                                ? null
                                : () => _applyPromotion(context),
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                    if (provider.appliedPromotionCode != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Applied: ${provider.appliedPromotionCode}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: provider.isApplyingPromotion
                                ? null
                                : () => _removePromotion(context),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    ],
                    if (provider.promotionPreview != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: provider.promotionPreview!.eligible
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          provider.promotionPreview!.message ?? 'Promotion preview ready',
                          style: TextStyle(
                            color: provider.promotionPreview!.eligible
                                ? Colors.green.shade900
                                : Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _summaryRow(
                      context,
                      'Subtotal',
                      '${AppConstants.currency}${provider.subtotal.toStringAsFixed(2)}',
                    ),
                    if (provider.discount > 0) ...[
                      const SizedBox(height: 6),
                      _summaryRow(
                        context,
                        'Discount',
                        '-${AppConstants.currency}${provider.discount.toStringAsFixed(2)}',
                      ),
                    ],
                    const SizedBox(height: 6),
                    _summaryRow(
                      context,
                      'Shipping',
                      '${AppConstants.currency}${provider.shipping.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 6),
                    _summaryRow(
                      context,
                      'Tax',
                      '${AppConstants.currency}${provider.tax.toStringAsFixed(2)}',
                    ),
                    const Divider(height: 20),
                    _summaryRow(
                      context,
                      'Total',
                      '${AppConstants.currency}${provider.total.toStringAsFixed(2)}',
                      isBold: true,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CheckoutScreen(),
                            ),
                          );
                        },
                        child: const Text('Proceed to Checkout'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmRemoveItem(BuildContext context, String itemId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove item'),
          content: const Text('Do you want to remove this item from cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    try {
      await context.read<CartProvider>().removeItem(itemId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item removed')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove item')),
      );
    }
  }

  Future<void> _confirmClearCart(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear cart'),
          content: const Text('This will remove all items from your cart.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true || !context.mounted) {
      return;
    }

    await context.read<CartProvider>().clearCart();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cart cleared')));
  }

  Future<void> _previewPromotion(BuildContext context) async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a promotion code')),
      );
      return;
    }

    try {
      await context.read<CartProvider>().previewPromotionCode(code);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to preview promotion code')),
      );
    }
  }

  Future<void> _applyPromotion(BuildContext context) async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a promotion code')),
      );
      return;
    }

    try {
      await context.read<CartProvider>().applyPromotionCode(code);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promotion applied')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to apply promotion code')),
      );
    }
  }

  Future<void> _scanPromotionCode(BuildContext context) async {
    String? rawValue;

    try {
      rawValue = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const _PromotionQrScannerScreen()),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      rawValue = _scannerFallbackToken;
    }

    if (rawValue == _scannerFallbackToken && context.mounted) {
      rawValue = await _openScanFallbackInput(context);
    }

    if (rawValue == null || rawValue.trim().isEmpty || !context.mounted) {
      return;
    }

    final parsedCode = _extractPromotionCode(rawValue);
    if (parsedCode == null || parsedCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read a promotion code from QR')),
      );
      return;
    }

    _promoController.text = parsedCode;
    await _applyPromotion(context);
  }

  Future<String?> _openScanFallbackInput(BuildContext context) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Scan Fallback'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Camera scanner is unavailable on this platform. Paste the QR content or promotion code.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'QR content or code',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Use'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return value;
  }

  String? _extractPromotionCode(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri != null) {
      final codeParam = uri.queryParameters['code'] ?? uri.queryParameters['promo'];
      if (codeParam != null && codeParam.trim().isNotEmpty) {
        return codeParam.trim().toUpperCase();
      }

      if (uri.pathSegments.isNotEmpty && uri.pathSegments.last.trim().isNotEmpty) {
        final lastSegment = uri.pathSegments.last.trim();
        if (lastSegment.length <= 30 && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(lastSegment)) {
          return lastSegment.toUpperCase();
        }
      }
    }

    if (value.startsWith('{') && value.endsWith('}')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          final dynamic code = decoded['code'] ?? decoded['promo'] ?? decoded['promotionCode'];
          if (code != null && code.toString().trim().isNotEmpty) {
            return code.toString().trim().toUpperCase();
          }
        }
      } catch (_) {}
    }

    if (value.toUpperCase().startsWith('PROMO:')) {
      final promoCode = value.substring(6).trim();
      if (promoCode.isNotEmpty) {
        return promoCode.toUpperCase();
      }
    }

    if (RegExp(r'^[A-Za-z0-9_-]{3,30}$').hasMatch(value)) {
      return value.toUpperCase();
    }

    return null;
  }

  Future<void> _removePromotion(BuildContext context) async {
    try {
      await context.read<CartProvider>().removePromotionCode();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promotion removed')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove promotion code')),
      );
    }
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
  }) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
      fontSize: isBold ? 16 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          value,
          style: style.copyWith(color: Theme.of(context).primaryColor),
        ),
      ],
    );
  }
}

class _PromotionQrScannerScreen extends StatefulWidget {
  const _PromotionQrScannerScreen();

  @override
  State<_PromotionQrScannerScreen> createState() => _PromotionQrScannerScreenState();
}

class _PromotionQrScannerScreenState extends State<_PromotionQrScannerScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Promotion QR')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) {
            return;
          }

          final code = capture.barcodes
              .map((barcode) => barcode.rawValue)
              .whereType<String>()
              .firstWhere(
                (value) => value.trim().isNotEmpty,
                orElse: () => '',
              );

          if (code.isEmpty) {
            return;
          }

          _handled = true;
          Navigator.of(context).pop(code);
        },
        errorBuilder: (context, error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off_outlined, size: 42),
                  const SizedBox(height: 10),
                  const Text(
                    'Camera scanner is unavailable right now.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(
                      _scannerFallbackToken,
                    ),
                    child: const Text('Enter code manually'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
