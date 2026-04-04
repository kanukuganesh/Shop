import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../models/product.dart';

class AdminAddProductScreen extends StatefulWidget {
  const AdminAddProductScreen({super.key});

  @override
  State<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends State<AdminAddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _category = 'Seasonal';
  String _description = '';
  double _price = 0.0;
  String _unit = 'per kg';
  bool _inStock = true;
  int _quantity = 100;
  String _imageUrl = '';

  final List<String> _categories = ['Seasonal', 'Tropical', 'Citrus', 'Pome Fruit', 'Berries', 'Grapes', 'Melons', 'Stone Fruit', 'Daily Essentials', 'Exotic'];
  final List<String> _units = ['per kg', 'per piece', 'per box', 'per dozen', 'per 500g'];

  void _saveProduct(BuildContext context, bool addAnother) {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final newProduct = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // mock ID generator
      name: _name,
      category: _category,
      description: _description,
      price: _price,
      unit: _unit,
      inStock: _inStock,
      quantity: _quantity,
      image: _imageUrl.isEmpty ? 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080' : _imageUrl, // fallback fruit image
    );

    context.read<ProductProvider>().addProduct(newProduct);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product added successfully!'), backgroundColor: Colors.green),
    );

    if (addAnother) {
      _formKey.currentState!.reset();
      setState(() {
        _inStock = true;
      });
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/admin/inventory'),
        ),
        title: const Text('Add New Product', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Basic Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 450) {
                                return Column(
                                  children: [
                                    TextFormField(
                                      decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                      onSaved: (v) => _name = v!,
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                                      value: _category,
                                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                      onChanged: (v) => setState(() => _category = v!),
                                      onSaved: (v) => _category = v!,
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                      onSaved: (v) => _name = v!,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 1,
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                                      value: _category,
                                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                      onChanged: (v) => setState(() => _category = v!),
                                      onSaved: (v) => _category = v!,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                            maxLines: 3,
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            onSaved: (v) => _description = v!,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pricing & Units
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pricing & Units', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder(), prefixText: '₹ '),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Must be > 0';
                                    return null;
                                  },
                                  onSaved: (v) => _price = double.parse(v!),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                                  value: _unit,
                                  items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                                  onChanged: (v) => setState(() => _unit = v!),
                                  onSaved: (v) => _unit = v!,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stock & Media
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Stock & Media', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: 250,
                                child: TextFormField(
                                  decoration: const InputDecoration(labelText: 'Initial Quantity', border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                  initialValue: '100',
                                  validator: (v) => v == null || v.isEmpty || int.tryParse(v) == null ? 'Invalid integer' : null,
                                  onSaved: (v) => _quantity = int.parse(v!),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Available Now', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: _inStock,
                                    activeThumbColor: Colors.green,
                                    onChanged: (v) => setState(() => _inStock = v),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Image URL (Optional)', border: OutlineInputBorder(), hintText: 'https://images.unsplash.com/...'),
                            onSaved: (v) => _imageUrl = v ?? '',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => context.go('/admin/inventory'),
                        child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
                      ),
                      OutlinedButton(
                        onPressed: () => _saveProduct(context, true),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black)),
                        child: const Text('Save & Add Another', style: TextStyle(color: Colors.black)),
                      ),
                      ElevatedButton(
                        onPressed: () => _saveProduct(context, false),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                        child: const Text('Save Product'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
