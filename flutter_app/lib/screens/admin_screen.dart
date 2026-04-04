import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const Scaffold();
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to Shop'),
                  style: TextButton.styleFrom(foregroundColor: Colors.black87),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Admin Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('Welcome, ${auth.currentUser?.username}!', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(24)),
                      child: Text('Shop Owner', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    
                    final statsCard = Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.inventory_2, size: 20),
                                SizedBox(width: 8),
                                Text('Quick Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildStatRow('Total Products', '10', Colors.black),
                            const Divider(),
                            _buildStatRow('Products In Stock', '10', Colors.green),
                            const Divider(),
                            _buildStatRow('Out of Stock', '0', Colors.red),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => context.go('/admin/orders'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                                child: const Text('View All Orders'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => context.go('/admin/inventory'),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black), foregroundColor: Colors.black),
                                child: const Text('Manage Inventory'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    final infoCard = Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person, size: 20),
                                SizedBox(width: 8),
                                Text('Account Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('Username', auth.currentUser?.username ?? 'Admin'),
                            const Divider(),
                            _buildInfoRow('Role', 'Administrator'),
                            const Divider(),
                            _buildInfoRow('Access Level', 'Full Access', Colors.green),
                          ],
                        ),
                      ),
                    );

                    final accountManagementCard = Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.red.shade100), borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.people_outline, size: 20),
                                SizedBox(width: 8),
                                Text('Account Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Reset customer registry and clear all user data except for the admin account.', 
                              style: TextStyle(color: Colors.grey, fontSize: 13)
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _confirmDeleteAllUsers(context, auth),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Delete All Customers'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    if (isMobile) {
                      return Column(
                        children: [
                          statsCard,
                          const SizedBox(height: 24),
                          infoCard,
                          const SizedBox(height: 24),
                          accountManagementCard,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: statsCard),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            children: [
                              infoCard,
                              const SizedBox(height: 24),
                              accountManagementCard,
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                const _AdminPaymentConfigPanel(),
                
                const SizedBox(height: 24),
                const _AdminBrandingPanel(),
                
                const SizedBox(height: 24),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.group, size: 20),
                            SizedBox(width: 8),
                            Text('Registered Accounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Live Firebase Authorization Monitor', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                            }
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final users = snapshot.data?.docs ?? [];
                            if (users.isEmpty) {
                              return const Text('No users registered yet.');
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: users.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final userDoc = users[index].data() as Map<String, dynamic>;
                                final username = userDoc['username'] ?? 'Unknown';
                                final password = userDoc['password'] ?? 'Unknown';
                                final pHint = userDoc['passwordHint'] ?? 'N/A';
                                final isAdmin = userDoc['isAdmin'] == true;
                                
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isAdmin ? Colors.green.shade100 : Colors.blue.shade50,
                                    child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person, color: isAdmin ? Colors.green : Colors.blueGrey),
                                  ),
                                  title: Text('$username', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Password: $password', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                      Text('Hint: $pHint', style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  trailing: isAdmin ? const Text('ADMIN', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)) : const Text('USER', style: TextStyle(color: Colors.grey)),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor ?? Colors.black)),
        ],
      ),
    );
  }

  void _confirmDeleteAllUsers(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Are you absolutely sure?'),
          content: const Text(
            'This action will permanently delete all customer accounts and their saved data. '
            'Only the administrator account will remain. This cannot be undone.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await auth.deleteAllUsersExceptAdmin();
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All users deleted successfully.'), backgroundColor: Colors.green),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete users.'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class _AdminPaymentConfigPanel extends StatefulWidget {
  const _AdminPaymentConfigPanel();

  @override
  State<_AdminPaymentConfigPanel> createState() => _AdminPaymentConfigPanelState();
}

class _AdminPaymentConfigPanelState extends State<_AdminPaymentConfigPanel> {
  final _upiIdCtrl = TextEditingController();
  final _payeeNameCtrl = TextEditingController();
  bool _isOnlineEnabled = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('payment').get();
      if (doc.exists) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _upiIdCtrl.text = data['upiId'] ?? '';
            _payeeNameCtrl.text = data['payeeName'] ?? '';
            _isOnlineEnabled = data['isOnlineEnabled'] ?? true;
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('settings').doc('payment').set({
        'upiId': _upiIdCtrl.text.trim(),
        'payeeName': _payeeNameCtrl.text.trim(),
        'isOnlineEnabled': _isOnlineEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Settings Saved Successfully', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())));
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payments, size: 20),
                SizedBox(width: 8),
                Text('Payment & Shop Routes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Enable Online Payments (UPI)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_isOnlineEnabled ? 'Active (Ready to receive payments)' : 'Disabled - Cash on Delivery Only', style: TextStyle(color: _isOnlineEnabled ? Colors.green : Colors.red)),
              value: _isOnlineEnabled,
              activeThumbColor: Colors.green,
              onChanged: (val) => setState(() => _isOnlineEnabled = val),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _upiIdCtrl,
              enabled: _isOnlineEnabled,
              decoration: InputDecoration(labelText: 'Target UPI ID', hintText: 'e.g., nagaraju@ybl', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.account_balance_wallet)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _payeeNameCtrl,
              enabled: _isOnlineEnabled,
              decoration: InputDecoration(labelText: 'Payee Name', hintText: 'e.g., K Nagaraju', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.person)),
            ),
            const SizedBox(height: 24),
            SizedBox(
               width: double.infinity,
               child: ElevatedButton.icon(
                 onPressed: _isSaving ? null : _saveSettings,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.black,
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                 ),
                 icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                 label: Text(_isSaving ? 'Saving Route...' : 'Save Configuration'),
               ),
            ),
          ],
        ),
      ),
    );
  }
}
class _AdminBrandingPanel extends StatefulWidget {
  const _AdminBrandingPanel();

  @override
  State<_AdminBrandingPanel> createState() => _AdminBrandingPanelState();
}

class _AdminBrandingPanelState extends State<_AdminBrandingPanel> {
  final _appNameCtrl = TextEditingController();
  final _appIconUrlCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _appNameCtrl.text = settings.appName;
    _appIconUrlCtrl.text = settings.appIconUrl ?? '';
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await context.read<SettingsProvider>().updateBranding(
        name: _appNameCtrl.text.trim(),
        iconUrl: _appIconUrlCtrl.text.trim().isEmpty ? null : _appIconUrlCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Branding Updated!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.brush_outlined, size: 20),
                SizedBox(width: 8),
                Text('App Branding & Identity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Manage how your shop appears to customers.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            TextField(
              controller: _appNameCtrl,
              decoration: const InputDecoration(labelText: 'Shop Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.storefront_outlined)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _appIconUrlCtrl,
              decoration: const InputDecoration(labelText: 'App Icon URL (PNG/SVG)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.image_outlined), helperText: 'Provide a direct link to your logo image'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline),
                label: Text(_isSaving ? 'Updating...' : 'Apply Branding Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
