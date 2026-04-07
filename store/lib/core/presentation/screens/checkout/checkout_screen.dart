import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController(text: 'US');
  final _phoneController = TextEditingController();

  String _paymentMethod = 'cod';

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cartProvider.items.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shipping Address',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _input(_fullNameController, 'Full Name'),
                    _input(_addressController, 'Address'),
                    Row(
                      children: [
                        Expanded(child: _input(_cityController, 'City')),
                        const SizedBox(width: 10),
                        Expanded(child: _input(_stateController, 'State')),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _input(_zipController, 'Zip Code')),
                        const SizedBox(width: 10),
                        Expanded(child: _input(_countryController, 'Country')),
                      ],
                    ),
                    _input(_phoneController, 'Phone'),
                    const SizedBox(height: 16),
                    Text(
                      'Payment Method',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _paymentMethod,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'cod', child: Text('Cash on Delivery')),
                        DropdownMenuItem(value: 'stripe', child: Text('Stripe')),
                        DropdownMenuItem(value: 'chapa', child: Text('Chapa')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _paymentMethod = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Order Summary',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _summaryRow(context, 'Subtotal', cartProvider.subtotal.toStringAsFixed(2)),
                    _summaryRow(context, 'Shipping', cartProvider.shipping.toStringAsFixed(2)),
                    _summaryRow(context, 'Tax', cartProvider.tax.toStringAsFixed(2)),
                    const Divider(height: 20),
                    _summaryRow(
                      context,
                      'Total',
                      cartProvider.total.toStringAsFixed(2),
                      isBold: true,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: orderProvider.isLoading ? null : _placeOrder,
                        child: orderProvider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Place Order'),
                      ),
                    ),
                    if (orderProvider.error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        orderProvider.error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _input(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value, {bool isBold = false}) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
      fontSize: isBold ? 16 : 14,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style.copyWith(color: Theme.of(context).primaryColor)),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final orderProvider = context.read<OrderProvider>();
    final cartProvider = context.read<CartProvider>();

    final order = await orderProvider.placeOrder(
      shippingAddress: {
        'fullName': _fullNameController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zipCode': _zipController.text.trim(),
        'country': _countryController.text.trim(),
        'phone': _phoneController.text.trim(),
      },
      paymentMethod: _paymentMethod,
    );

    if (!mounted) {
      return;
    }

    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order')),
      );
      return;
    }

    await cartProvider.loadCart();
    await context.read<ProductProvider>().refreshProducts();
    await context.read<ProductProvider>().loadFeaturedProducts();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order placed: ${order.id}')),
    );

    Navigator.of(context).pushNamedAndRemoveUntil('/orders', (route) => route.isFirst);
  }
}
