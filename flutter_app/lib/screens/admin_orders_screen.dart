import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'all';

  void _updateOrderStatus(BuildContext context, String orderId, String newStatus) {
     context.read<OrderProvider>().updateOrderStatus(orderId, newStatus);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const Scaffold();
    }

    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: StreamBuilder<List<OrderModel>>(
              stream: orderProvider.adminOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(48.0), child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading orders: ${snapshot.error}'));
                }

                final List<OrderModel> allOrders = snapshot.data ?? [];

                final filteredOrders = allOrders.where((order) {
                  final searchLower = _searchController.text.toLowerCase();
                  final matchesSearch = order.id.toLowerCase().contains(searchLower) ||
                      order.customerName.toLowerCase().contains(searchLower) ||
                      order.customerMobile.contains(searchLower);
                  final matchesStatus = _statusFilter == 'all' || order.status == _statusFilter;
                  return matchesSearch && matchesStatus;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.go('/admin'),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Back to Dashboard'),
                      style: TextButton.styleFrom(foregroundColor: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                          child: Icon(Icons.inventory_2, size: 32, color: Colors.green.shade600),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Live Shop Orders', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              Text('Real-time synchronization with customer apps', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stats = [
                          _buildStatCard('Total Orders', allOrders.length.toString(), Colors.black),
                          _buildStatCard('Processing', allOrders.where((o) => o.status == 'processing').length.toString(), Colors.yellow.shade800),
                          _buildStatCard('Delivered', allOrders.where((o) => o.status == 'delivered').length.toString(), Colors.green.shade600),
                          _buildStatCard('Cancelled', allOrders.where((o) => o.status == 'cancelled').length.toString(), Colors.red.shade600),
                        ];

                        if (constraints.maxWidth < 600) {
                          return Column(
                            children: [
                              Row(children: [stats[0], const SizedBox(width: 8), stats[1]]),
                              const SizedBox(height: 8),
                              Row(children: [stats[2], const SizedBox(width: 8), stats[3]]),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            stats[0], const SizedBox(width: 16),
                            stats[1], const SizedBox(width: 16),
                            stats[2], const SizedBox(width: 16),
                            stats[3],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Orders Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final searchField = TextField(
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.search),
                                    hintText: 'Search orders by ID or customer...',
                                  ),
                                );

                                final dropdownField = DropdownButtonFormField<String>(
                                  value: _statusFilter,
                                  decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.filter_list)),
                                  items: const [
                                    DropdownMenuItem(value: 'all', child: Text('All Orders')),
                                    DropdownMenuItem(value: 'processing', child: Text('Processing')),
                                    DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _statusFilter = val);
                                  },
                                );

                                if (constraints.maxWidth < 600) {
                                  return Column(
                                    children: [
                                      searchField,
                                      const SizedBox(height: 12),
                                      dropdownField,
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(flex: 2, child: searchField),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 1, child: dropdownField),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            if (filteredOrders.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text('No Orders Found matching criteria', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredOrders.length,
                                itemBuilder: (context, index) {
                                  final order = filteredOrders[index];
                                  final recentlyModified = DateTime.now().difference(order.lastModified).inMinutes < 5;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    elevation: recentlyModified ? 4 : 0,
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                          color: recentlyModified ? Colors.orange : Colors.grey.shade300,
                                          width: recentlyModified ? 2 : 1),
                                      borderRadius: BorderRadius.circular(8)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                            final paymentBadgeColor = order.paymentMethod.toLowerCase() == 'cod' && order.paymentStatus == 'Pending'
                                                ? Colors.blue.shade100 
                                                : (order.paymentStatus == 'Paid' ? Colors.green.shade100 : (order.paymentStatus == 'Awaiting Verification' ? Colors.orange.shade100 : Colors.yellow.shade100));
                                            final paymentBadgeText = order.paymentMethod.toLowerCase() == 'cod' && order.paymentStatus == 'Pending' ? 'COD - Pending' : '${order.paymentMethod.toUpperCase()} - ${order.paymentStatus}';

                                            final customerInfo = Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: order.status == 'delivered' ? Colors.green.shade100 : (order.status == 'processing' ? Colors.yellow.shade100 : Colors.red.shade100),
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      child: Text(order.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: paymentBadgeColor,
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      child: Text(paymentBadgeText.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                    ),
                                                    if (recentlyModified)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                                                        child: const Text('NEW UPDATE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                                      ),
                                                  ],
                                                ),
                                              const SizedBox(height: 8),
                                              Text('Customer: ${order.customerName}', style: TextStyle(color: Colors.grey.shade700)),
                                              Text('Mobile: ${order.customerMobile}', style: TextStyle(color: Colors.grey.shade700)),
                                              Text('Date: ${order.date.toIso8601String().split('T')[0]}', style: TextStyle(color: Colors.grey.shade700)),
                                            ],
                                          );

                                          final orderInfo = Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Items: ${order.items.map((i) => "${i.quantity}x ${i.name}").join(', ')}', style: TextStyle(color: Colors.grey.shade700)),
                                              Text('Delivery: ${order.deliveryAddress.street}, ${order.deliveryAddress.city} - ${order.deliveryAddress.pinCode}', style: TextStyle(color: Colors.grey.shade700)),
                                              const SizedBox(height: 8),
                                              Text('Total: ₹${order.totalAmount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green.shade600)),
                                            ],
                                          );

                                          final actions = order.status == 'processing' ? Padding(
                                            padding: const EdgeInsets.only(top: 16),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () => _updateOrderStatus(context, order.id, 'cancelled'),
                                                  child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed: () => _updateOrderStatus(context, order.id, 'delivered'),
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                                  child: const Text('Mark Delivered'),
                                                ),
                                              ],
                                            ),
                                          ) : const SizedBox.shrink();

                                          final verificationBox = order.paymentStatus == 'Awaiting Verification' ? Container(
                                              margin: const EdgeInsets.only(top: 16),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(color: Colors.orange.shade50, border: Border.all(color: Colors.orange), borderRadius: BorderRadius.circular(8)),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Payment Verification Required', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                                  const SizedBox(height: 8),
                                                  Text('User uploaded UTR: ${order.transactionId ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    children: [
                                                      ElevatedButton(
                                                        onPressed: () => context.read<OrderProvider>().updatePaymentDetails(order.id, order.paymentMethod, 'Paid', order.transactionId),
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                                        child: const Text('Verify'),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      OutlinedButton(
                                                        onPressed: () => context.read<OrderProvider>().updatePaymentDetails(order.id, 'COD', 'Failed', null),
                                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                                        child: const Text('Reject'),
                                                      ),
                                                    ],
                                                  )
                                                ],
                                              )
                                          ) : const SizedBox.shrink();

                                          if (constraints.maxWidth < 500) {
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                customerInfo,
                                                const Divider(height: 24),
                                                orderInfo,
                                                verificationBox,
                                                actions,
                                              ],
                                            );
                                          }
                                          return Column(
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: customerInfo),
                                                  Expanded(child: orderInfo),
                                                ],
                                              ),
                                              verificationBox,
                                              actions,
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color valueColor) {
    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: valueColor)),
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
