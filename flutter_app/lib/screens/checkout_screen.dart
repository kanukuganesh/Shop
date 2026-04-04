import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../models/address.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upi_pay/upi_pay.dart';
import 'package:upi_payment_qrcode_generator/upi_payment_qrcode_generator.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Guest/New Address Form
  String firstName = '';
  String lastName = '';
  String email = '';
  String street = '';
  String city = '';
  String zipCode = '';
  bool saveAsDefault = false;
  
  String? selectedAddressId;
  bool showAddressForm = false;
  String paymentMethod = 'cod';

  bool isProcessing = false;
  bool orderComplete = false;

  bool _isLoadingConfig = true;
  bool _isOnlineEnabled = false;
  String _upiId = '';
  String _payeeName = '';
  List<ApplicationMeta> _upiApps = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null && auth.currentUser!.addresses.isNotEmpty) {
        final defaultAddr = auth.currentUser!.addresses.where((a) => a.isDefault).firstOrNull ?? auth.currentUser!.addresses.first;
        setState(() {
          selectedAddressId = defaultAddr.id;
          firstName = auth.currentUser!.username; // Autopopulate
          showAddressForm = false;
        });
      } else {
        setState(() {
          showAddressForm = true;
        });
      }
    });
  }

  Future<void> _loadConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('payment').get();
      if (doc.exists) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _isOnlineEnabled = data['isOnlineEnabled'] ?? false;
            _upiId = data['upiId'] ?? '';
            _payeeName = data['payeeName'] ?? '';
          });
        }
      }
      final apps = await UpiPay().getInstalledUpiApplications(statusType: UpiApplicationDiscoveryAppStatusType.all);
      if (mounted) {
         setState(() {
            _upiApps = apps;
            _isLoadingConfig = false;
         });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingConfig = false);
    }
  }

  Future<void> _submitOrder(BuildContext context, CartProvider cart, AuthProvider auth, OrderProvider orderProvider) async {
    // Determine the final address
    Address? finalAddress;

    if (showAddressForm) {
      if (!_formKey.currentState!.validate()) return;
      _formKey.currentState!.save();
      
      finalAddress = Address(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'Home',
        street: street,
        city: city,
        pinCode: zipCode,
        isDefault: saveAsDefault,
      );

      // Save to profile if logged in
      if (auth.currentUser != null) {
        // Fire-and-forget: Optimistic caching unblocks the main thread
        auth.addAddress(finalAddress);
      }
    } else {
      if (selectedAddressId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a delivery address')));
        return;
      }
      finalAddress = auth.currentUser!.addresses.firstWhere((a) => a.id == selectedAddressId);
      // Ensure we have a name
      if (firstName.isEmpty) {
         if (!_formKey.currentState!.validate()) return;
         _formKey.currentState!.save();
      }
    }

    setState(() {
      isProcessing = true;
    });

    final orderId = '#NF-${(1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toInt()}';
    final customerName = showAddressForm ? '$firstName $lastName'.trim() : auth.currentUser?.username ?? 'Guest';
    
    final order = OrderModel(
      id: orderId,
      userId: auth.currentUser?.username ?? 'Guest',
      customerName: customerName,
      customerMobile: auth.currentUser?.username ?? 'Guest', // Assuming username is mobile for now
      date: DateTime.now(),
      status: 'processing',
      totalAmount: cart.getCartTotal(),
      items: cart.cartItems.map((item) => OrderItem(
        productId: item.product.id,
        name: item.product.name,
        price: item.product.price,
        quantity: item.quantity,
        unit: item.product.unit,
      )).toList(),
      deliveryAddress: finalAddress,
      paymentMethod: paymentMethod,
      paymentStatus: 'Pending',
      transactionId: null,
      lastModified: DateTime.now(),
    );

    try {
      // Intentionally NOT awaiting the server response to make the UI instant
      orderProvider.createOrder(order);
      
      cart.clearCart();
      setState(() {
        isProcessing = false;
        orderComplete = true;
      });
    } catch (e) {
      setState(() {
        isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (orderComplete) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              const Text('Order Confirmed!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Thank you for your order. We\'ll process it right away.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      );
    }

    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();

    if (cart.cartItems.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 1024;
      
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: isWide ? 2 : 0,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Identity Card
                          if (auth.currentUser != null && !showAddressForm) 
                            _buildCard(
                              title: 'Contact Details',
                              icon: Icons.person,
                              child: Text('Ordering as: ${auth.currentUser!.username}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            )
                          else
                            _buildCard(
                              title: 'Contact Information',
                              icon: Icons.person,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: TextFormField(
                                        initialValue: firstName,
                                        decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                                        validator: (v) => v!.isEmpty ? 'Required' : null,
                                        onSaved: (v) => firstName = v!,
                                      )),
                                      const SizedBox(width: 16),
                                      Expanded(child: TextFormField(
                                        decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
                                        validator: (v) => v!.isEmpty ? 'Required' : null,
                                        onSaved: (v) => lastName = v!,
                                      )),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    decoration: const InputDecoration(labelText: 'Mobile or Email', border: OutlineInputBorder()),
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                    onSaved: (v) => email = v!,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),
                          // Shipping Address Box
                          _buildCard(
                            title: 'Delivery Address',
                            icon: Icons.pin_drop,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (auth.currentUser != null && auth.currentUser!.addresses.isNotEmpty) ...[
                                  ...auth.currentUser!.addresses.map((addr) => RadioListTile<String>(
                                    title: Text(addr.type, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('${addr.street}, ${addr.city} - ${addr.pinCode}'),
                                    value: addr.id,
                                    groupValue: selectedAddressId,
                                    activeColor: Colors.green,
                                    onChanged: (val) {
                                      setState(() {
                                        selectedAddressId = val;
                                        showAddressForm = false;
                                      });
                                    },
                                  )).toList(),
                                  const Divider(),
                                  TextButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add New Address'),
                                    onPressed: () {
                                      setState(() {
                                        showAddressForm = true;
                                        selectedAddressId = null;
                                      });
                                    },
                                  ),
                                ],
                                
                                if (showAddressForm) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    decoration: const InputDecoration(labelText: 'Street Address', border: OutlineInputBorder()),
                                    validator: (v) => showAddressForm && v!.isEmpty ? 'Required' : null,
                                    onSaved: (v) => street = v ?? '',
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(child: TextFormField(
                                        decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                                        validator: (v) => showAddressForm && v!.isEmpty ? 'Required' : null,
                                        onSaved: (v) => city = v ?? '',
                                      )),
                                      const SizedBox(width: 16),
                                      Expanded(child: TextFormField(
                                        decoration: const InputDecoration(labelText: 'PIN Code', border: OutlineInputBorder()),
                                        validator: (v) => showAddressForm && v!.isEmpty ? 'Required' : null,
                                        onSaved: (v) => zipCode = v ?? '',
                                      )),
                                    ],
                                  ),
                                  if (auth.currentUser != null) ...[
                                    const SizedBox(height: 16),
                                    CheckboxListTile(
                                      title: const Text("Save as default delivery address"),
                                      value: saveAsDefault,
                                      onChanged: (val) {
                                        setState(() {
                                          saveAsDefault = val ?? false;
                                        });
                                      },
                                    ),
                                  ]
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Payment Method
                          if (_isLoadingConfig)
                             const CircularProgressIndicator()
                          else
                             _buildCard(
                               title: 'Payment Method',
                               icon: Icons.payment,
                               child: Column(
                                 children: [
                                   _buildRadioTile('cod', 'Cash on Delivery', 'Pay when you receive your order', Icons.money),
                                   
                                   if (_isOnlineEnabled && _upiId.isNotEmpty) ...[
                                      _buildRadioTile('upi', 'UPI Payment', 'PhonePe, Google Pay, Paytm, or Scan QR', Icons.smartphone),
                                      if (paymentMethod == 'upi') ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(border: Border.all(color: Colors.green.shade200), borderRadius: BorderRadius.circular(8)),
                                          child: Column(
                                            children: [
                                              const Text('Scan using any UPI App', style: TextStyle(fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 16),
                                              UPIPaymentQRCode(
                                                 upiDetails: UPIDetails(
                                                    upiID: _upiId,
                                                    payeeName: _payeeName.isNotEmpty ? _payeeName : "Merchant",
                                                    amount: cart.getCartTotal(),
                                                    transactionNote: "Order Payment",
                                                 ),
                                                 size: 200,
                                              ),
                                              const SizedBox(height: 16),
                                              if (_upiApps.isNotEmpty)
                                                 Wrap(
                                                   spacing: 8,
                                                   runSpacing: 8,
                                                   children: _upiApps.map((app) => OutlinedButton.icon(
                                                     onPressed: () async {
                                                        try {
                                                          await UpiPay().initiateTransaction(
                                                            amount: cart.getCartTotal().toStringAsFixed(2),
                                                            app: app.upiApplication,
                                                            receiverName: _payeeName.isNotEmpty ? _payeeName : "Merchant",
                                                            receiverUpiAddress: _upiId,
                                                            transactionRef: "#NF-${DateTime.now().millisecondsSinceEpoch}",
                                                            transactionNote: 'Order Checkout',
                                                          );
                                                        } catch (_) {}
                                                     },
                                                     icon: app.iconImage(20),
                                                     label: Text(app.upiApplication.getAppName()),
                                                   )).toList()
                                                 )
                                              else 
                                                 const Text('No UPI apps found on this device', style: TextStyle(color: Colors.red)),
                                            ]
                                          )
                                        )
                                      ]
                                   ] else ...[
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                        child: const Row(
                                           children: [
                                              Icon(Icons.warning_amber_rounded, color: Colors.red),
                                              SizedBox(width: 12),
                                              Expanded(child: Text('Online transaction is not working, place on cash on delivery', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                           ]
                                        ),
                                      ),
                                   ]
                                 ],
                               ),
                             ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isProcessing ? null : () => _submitOrder(context, cart, auth, orderProvider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                              ),
                              child: Text(
                                isProcessing ? 'Processing...' : (paymentMethod == 'cod' ? 'Place Order - ₹${cart.getCartTotal().toStringAsFixed(0)}' : 'Pay ₹${cart.getCartTotal().toStringAsFixed(0)}'),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isWide) const SizedBox(width: 32) else const SizedBox(height: 32),
                  // order summary
                  Flexible(
                    flex: isWide ? 1 : 0,
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ...cart.cartItems.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('${item.product.name} x ${item.quantity}', style: TextStyle(color: Colors.grey.shade600))),
                                  Text('₹${(item.product.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            )),
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Subtotal', style: TextStyle(color: Colors.grey.shade600)),
                                Text('₹${cart.getCartTotal().toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Shipping', style: TextStyle(color: Colors.grey.shade600)),
                                const Text('FREE', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text(
                                  '₹${cart.getCartTotal().toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8)
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile(String value, String title, String subtitle, IconData icon) {
    return InkWell(
      onTap: () {
        setState(() {
          paymentMethod = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: paymentMethod == value ? Colors.green.shade600 : Colors.grey.shade300, width: paymentMethod == value ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
          color: paymentMethod == value ? Colors.green.shade50 : Colors.transparent,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: paymentMethod,
              onChanged: (val) {
                if (val != null) setState(() => paymentMethod = val);
              },
            ),
            Icon(icon, color: Colors.grey.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
