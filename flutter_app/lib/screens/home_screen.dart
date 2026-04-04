import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determine grid columns based on screen width (Mobile First)
    int crossAxisCount = 2;
    if (screenWidth >= 1024) {
      crossAxisCount = 4;
    } else if (screenWidth >= 768) {
      crossAxisCount = 3;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            vertical: screenWidth < 600 ? 16 : 32, 
            horizontal: screenWidth < 600 ? 8 : 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fresh Fruits Delivered',
                    style: TextStyle(
                      fontSize: screenWidth < 600 ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Discover our selection of fresh, high-quality fruits',
                    style: TextStyle(
                      fontSize: screenWidth < 600 ? 14 : 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: screenWidth < 600 ? 16 : 32),
                  Consumer<ProductProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final products = provider.products.toList()
                        ..sort((a, b) {
                          // Move out of stock to bottom
                          if (a.inStock && !b.inStock) return -1;
                          if (!a.inStock && b.inStock) return 1;
                          return 0;
                        });

                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: screenWidth < 600 ? 0.55 : 0.65, 
                          crossAxisSpacing: screenWidth < 600 ? 12 : 24,
                          mainAxisSpacing: screenWidth < 600 ? 12 : 24,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ProductCardWidget(product: product);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
