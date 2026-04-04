import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../models/product.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  String? _editingProductId;
  final TextEditingController _priceController = TextEditingController();
  final Set<String> _selectedProducts = {};

  void _startEditing(Product product) {
    setState(() {
      _editingProductId = product.id;
      _priceController.text = product.price.toStringAsFixed(0);
    });
  }

  void _savePrice(ProductProvider provider) {
    if (_editingProductId != null) {
      final newPrice = double.tryParse(_priceController.text);
      if (newPrice != null && newPrice > 0) {
        provider.updateProductPrice(_editingProductId!, newPrice);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid price value. Price must be greater than 0.'), backgroundColor: Colors.red),
        );
      }
      setState(() {
        _editingProductId = null;
      });
    }
  }

  void _bulkMarkOutOfStock(ProductProvider provider) {
    for (String id in _selectedProducts) {
      // Find the product
      final productIndex = provider.products.indexWhere((p) => p.id == id);
      if (productIndex != -1 && provider.products[productIndex].inStock) {
        provider.toggleProductStock(id);
      }
    }
    setState(() {
      _selectedProducts.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selected products marked Out of Stock'), backgroundColor: Colors.orange),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    if (productProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final products = productProvider.products;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/admin'),
        ),
        title: const Text('Inventory Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (_selectedProducts.isNotEmpty)
            IconButton(
              onPressed: () => _bulkMarkOutOfStock(productProvider),
              icon: const Icon(Icons.inventory_2_outlined, color: Colors.orange),
              tooltip: 'Mark Out of Stock (${_selectedProducts.length})',
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: () => context.go('/admin/products/new'),
              icon: const Icon(Icons.add_circle, color: Colors.black, size: 28),
              tooltip: 'Add New Product',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Edit', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: true,
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                  columns: const [
                    DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Price (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Stock Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: products.map((product) {
                    final isEditing = _editingProductId == product.id;
                    return DataRow(
                      selected: _selectedProducts.contains(product.id),
                      onSelectChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedProducts.add(product.id);
                          } else {
                            _selectedProducts.remove(product.id);
                          }
                        });
                      },
                      color: MaterialStateProperty.resolveWith((states) {
                        if (!product.inStock) {
                          return Colors.red.shade50.withOpacity(0.5); // Greyish/reddish out for out of stock
                        }
                        return null;
                      }),
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  image: DecorationImage(image: NetworkImage(product.image), fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(product.name, style: TextStyle(fontWeight: FontWeight.bold, color: product.inStock ? Colors.black : Colors.grey.shade700)),
                            ],
                          ),
                        ),
                        DataCell(Text(product.category)),
                        DataCell(
                          isEditing
                              ? SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: _priceController,
                                    keyboardType: TextInputType.number,
                                    autofocus: true,
                                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                    onSubmitted: (_) => _savePrice(productProvider),
                                  ),
                                )
                              : InkWell(
                                  onTap: () => _startEditing(product),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 1, style: BorderStyle.solid), borderRadius: BorderRadius.circular(4)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('₹${product.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 4),
                                        Icon(Icons.edit, size: 14, color: Colors.grey.shade500),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                        DataCell(Text(product.unit)),
                        DataCell(
                          Switch(
                            value: product.inStock,
                            activeColor: Colors.green,
                            onChanged: (val) {
                              productProvider.toggleProductStock(product.id);
                            },
                          ),
                        ),
                        DataCell(Text('${product.quantity ?? 0}')),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: () {
                                  productProvider.deleteProduct(product.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
