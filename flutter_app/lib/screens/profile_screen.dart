import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upi_pay/upi_pay.dart';
import 'package:upi_payment_qrcode_generator/upi_payment_qrcode_generator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showPassword = false;
  final _newPasswordController = TextEditingController();

  void _showChangePasswordDialog(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your new password below.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red),
                  );
                  return;
                }
                final success = await auth.changePassword(_newPasswordController.text);
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    _newPasswordController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update password'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
              child: const Text('Update Password'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold();
    }

    final user = auth.currentUser!;
    final memberYear = user.memberSince?.year.toString() ?? DateTime.now().year.toString();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/'),
        ),
        title: const Text('My Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.green.shade50,
                        backgroundImage: user.profilePictureUrl != null ? NetworkImage(user.profilePictureUrl!) : null,
                        child: user.profilePictureUrl == null 
                          ? Text(user.username[0].toUpperCase(), style: TextStyle(fontSize: 32, color: Colors.green.shade700, fontWeight: FontWeight.bold))
                          : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName ?? user.username,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Text(
                          'Member since $memberYear',
                          style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          // TODO: Implement Edit Profile
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Profile coming soon!')));
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Edit Profile', style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Navigation Sections
                _buildSectionTitle('Identity & Contact'),
                _buildProfileCard([
                  _buildProfileItem(Icons.person_outline, 'Full Name', subtitle: user.fullName ?? 'Not Set'),
                  _buildProfileItem(Icons.phone_android_outlined, 'Mobile Number', subtitle: user.phoneNumber ?? 'Not Set'),
                  _buildProfileItem(Icons.email_outlined, 'Email Address', subtitle: user.email ?? 'Not Set'),
                ]),

                _buildSectionTitle('Order & Transaction History'),
                _buildProfileCard([
                  _buildProfileItem(Icons.local_shipping_outlined, 'Active Orders', onTap: () {
                     _showOrdersDialog(context, 'processing');
                  }),
                  _buildProfileItem(Icons.history, 'Order History', onTap: () {
                     _showOrdersDialog(context, 'all');
                  }),
                  _buildProfileItem(Icons.receipt_long_outlined, 'Digital Invoices', onTap: () {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoices feature coming soon!')));
                  }),
                ]),

                _buildSectionTitle('Address & Logistics'),
                _buildProfileCard([
                  _buildProfileItem(Icons.map_outlined, 'Saved Addresses', onTap: () {
                    _showAddressesDialog(context, auth);
                  }),
                  _buildProfileItem(Icons.location_on_outlined, 'Location Pinning', subtitle: 'Manage precise delivery points'),
                ]),

                _buildSectionTitle('Payments & Loyalty'),
                _buildProfileCard([
                  _buildProfileItem(Icons.payment_outlined, 'Saved Payments', subtitle: 'UPI IDs & Cards'),
                  _buildProfileItem(Icons.account_balance_wallet_outlined, 'My Wallet', subtitle: 'Coins & Rewards'),
                ]),

                _buildSectionTitle('Account Settings'),
                _buildProfileCard([
                  _buildProfileItem(Icons.lock_outline, 'Change Password', onTap: () => _showChangePasswordDialog(auth)),
                  _buildProfileItem(Icons.notifications_none, 'Notification Settings', subtitle: 'Manage SMS & WhatsApp alerts'),
                ]),

                _buildSectionTitle('Support'),
                _buildProfileCard([
                  _buildProfileItem(Icons.help_outline, 'Help & Support'),
                  _buildProfileItem(Icons.privacy_tip_outlined, 'Privacy Policy'),
                ]),

                const SizedBox(height: 32),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => auth.logout(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.1),
        ),
      ),
    );
  }

  Widget _buildProfileCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final idx = entry.key;
          final widget = entry.value;
          final isLast = idx == children.length - 1;
          return Column(
            children: [
              widget,
              if (!isLast) Divider(height: 1, indent: 56, color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showOrdersDialog(BuildContext context, String filter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text(filter == 'all' ? 'Order History' : 'Active Orders', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: OrderHistoryInDialog(filter: filter),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddressesDialog(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('Saved Addresses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              if (auth.currentUser!.addresses.isEmpty)
                const Center(child: Text('No saved addresses yet.'))
              else
                ...auth.currentUser!.addresses.map((addr) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(addr.isDefault ? Icons.star : Icons.location_on, color: addr.isDefault ? Colors.orange : Colors.grey),
                    title: Text(addr.type),
                    subtitle: Text('${addr.street}, ${addr.city}'),
                    trailing: addr.isDefault ? null : TextButton(onPressed: () => auth.setDefaultAddress(addr.id), child: const Text('Set Default')),
                  ),
                )).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderHistoryInDialog extends StatelessWidget {
  final String filter;
  const OrderHistoryInDialog({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.read<OrderProvider>();
    final auth = context.read<AuthProvider>();

    return StreamBuilder<List<OrderModel>>(
      stream: orderProvider.userOrdersStream(auth.currentUser!.username),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        
        var orders = snapshot.data ?? [];
        if (filter != 'all') {
          orders = orders.where((o) => o.status == filter).toList();
        }

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 64),
                Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                const Text('No orders found yet!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                const Text('Your produce will appear here once ordered.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('Start Shopping'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: orders.map((order) => UserOrderCard(order: order)).toList(),
        );
      },
    );
  }
}

class UserOrderCard extends StatelessWidget {
  final OrderModel order;

  const UserOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.status == 'cancelled';
    final isDelivered = order.status == 'delivered';
    final isProcessing = order.status == 'processing';
    final canPayOnline = order.paymentMethod.toLowerCase() == 'cod' && order.paymentStatus == 'Pending' && !isCancelled && !isDelivered;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isCancelled ? Colors.grey.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isCancelled ? Colors.red.shade100 : Colors.grey.shade300), 
        borderRadius: BorderRadius.circular(8)
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.id, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isCancelled ? Colors.grey : Colors.black)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCancelled ? Colors.red.shade100 : (isDelivered ? Colors.green.shade100 : Colors.yellow.shade100),
                    borderRadius: BorderRadius.circular(16)
                  ),
                  child: Text(
                    order.status.toUpperCase(), 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isCancelled ? Colors.red.shade800 : Colors.black87)
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Ordered on: ${order.date.toIso8601String().split('T')[0]}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 12),
            ...order.items.map((item) => Text('${item.name} x ${item.quantity}', style: TextStyle(color: isCancelled ? Colors.grey : Colors.black87))),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, color: isCancelled ? Colors.grey : Colors.black)),
                Text('₹${order.totalAmount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isCancelled ? Colors.grey : Colors.green.shade700)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${order.paymentMethod.toUpperCase()} - ${order.paymentStatus}', style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: order.paymentStatus == 'Paid' ? Colors.green : (order.paymentStatus == 'Failed' ? Colors.red : Colors.orange)
                )),
              ],
            ),
            if (canPayOnline) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => LateUPIPaymentDialog(order: order),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Pay Online via UPI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            if (isProcessing) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<OrderProvider>().updateOrderStatus(order.id, 'cancelled');
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Cancelled Successfully'), backgroundColor: Colors.red));
                    }, 
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 16), 
                    label: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                  ),
                ],
              )
            ],
            if (isCancelled) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Quick reorder logic not fully implemented, routes to home for now
                     context.go('/');
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reorder Items'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class LateUPIPaymentDialog extends StatefulWidget {
  final OrderModel order;
  const LateUPIPaymentDialog({super.key, required this.order});

  @override
  State<LateUPIPaymentDialog> createState() => _LateUPIPaymentDialogState();
}

class _LateUPIPaymentDialogState extends State<LateUPIPaymentDialog> {
  bool _isLoadingConfig = true;
  bool _isOnlineEnabled = false;
  String _upiId = '';
  String _payeeName = '';
  List<ApplicationMeta> _upiApps = [];
  
  final _utrCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
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
  
  Future<void> _submitUTR(BuildContext context) async {
     if (_utrCtrl.text.trim().isEmpty) return;
     setState(() => _isSubmitting = true);
     
     try {
       await context.read<OrderProvider>().updatePaymentDetails(
         widget.order.id, 
         'UPI (Changed)', 
         'Awaiting Verification', 
         _utrCtrl.text.trim()
       );
       if (!mounted) return;
       Navigator.pop(context);
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Details Submitted for Verification!'), backgroundColor: Colors.green));
     } catch (e) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting: $e')));
       setState(() => _isSubmitting = false);
     }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingConfig) {
      return const AlertDialog(content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())));
    }
    
    if (!_isOnlineEnabled || _upiId.isEmpty) {
      return AlertDialog(
        title: const Text('Online Payments Currently Unavailable', style: TextStyle(color: Colors.red)),
        content: const Text('The shop owner has temporarily disabled online payments. Your order remains safely as Cash on Delivery.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ],
      );
    }

    return AlertDialog(
      title: Text('Pay for ${widget.order.id}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Scan using any UPI App', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            UPIPaymentQRCode(
               upiDetails: UPIDetails(
                  upiID: _upiId,
                  payeeName: _payeeName.isNotEmpty ? _payeeName : "Merchant",
                  amount: widget.order.totalAmount,
                  transactionNote: "Order ${widget.order.id}",
               ),
               size: 200,
            ),
            const SizedBox(height: 16),
            if (_upiApps.isNotEmpty) ...[
               const Text("Or Pay Direct:"),
               const SizedBox(height: 8),
               Wrap(
                 spacing: 8,
                 runSpacing: 8,
                 alignment: WrapAlignment.center,
                 children: _upiApps.map((app) => OutlinedButton.icon(
                   onPressed: () async {
                      try {
                        await UpiPay().initiateTransaction(
                          amount: widget.order.totalAmount.toStringAsFixed(2),
                          app: app.upiApplication,
                          receiverName: _payeeName.isNotEmpty ? _payeeName : "Merchant",
                          receiverUpiAddress: _upiId,
                          transactionRef: widget.order.id,
                          transactionNote: 'Order ${widget.order.id}',
                        );
                      } catch (_) {}
                   },
                   icon: app.iconImage(20),
                   label: Text(app.upiApplication.getAppName()),
                 )).toList()
               )
            ],
            const Divider(height: 32),
            const Text("After paying, enter your 12-digit UTR/Transaction ID below to verify your payment:", textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _utrCtrl,
              decoration: const InputDecoration(labelText: 'UTR / Transaction ID', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : () => _submitUTR(context), 
          child: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator()) : const Text('Submit UTR'),
        )
      ],
    );
  }
}
