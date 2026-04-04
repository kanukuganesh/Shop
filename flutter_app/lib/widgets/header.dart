import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class ShopHeader extends StatelessWidget implements PreferredSizeWidget {
  const ShopHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final itemCount = cartProvider.getCartItemsCount();
    final currentUser = authProvider.currentUser;

    final location = GoRouterState.of(context).uri.toString();
    final canGoBack = location != '/';

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: Colors.black12,
      iconTheme: const IconThemeData(color: Colors.black87),
      leading: canGoBack ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ) : null,
      title: InkWell(
        onTap: () => context.go('/'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (settings.appIconUrl != null)
              Image.network(settings.appIconUrl!, height: 32, width: 32, errorBuilder: (_, __, ___) => const Icon(Icons.energy_savings_leaf, color: Colors.green))
            else
              const Icon(Icons.energy_savings_leaf, color: Colors.green),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                settings.appName,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.go('/'),
          child: const Text('Shop', style: TextStyle(color: Colors.black87)),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {
                context.go('/cart');
              },
            ),
            if (itemCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$itemCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        if (currentUser != null)
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline),
            onSelected: (value) async {
              if (value == 'profile') {
                context.go('/profile');
              } else if (value == 'admin') {
                context.go('/admin');
              } else if (value == 'logout') {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  context.read<CartProvider>().loadUserCart('guest');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out successfully')),
                  );
                  context.go('/');
                }
              }
            },
            itemBuilder: (BuildContext context) {
              final List<PopupMenuEntry<String>> menuItems = [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser.username,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (authProvider.isAdmin)
                        const Text(
                          'Admin Account',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 20),
                      SizedBox(width: 8),
                      Text('My Profile'),
                    ],
                  ),
                ),
              ];

              if (authProvider.isAdmin) {
                menuItems.add(const PopupMenuDivider());
                menuItems.add(
                  const PopupMenuItem(
                    value: 'admin',
                    child: Row(
                      children: [
                        Icon(Icons.security, size: 20),
                        SizedBox(width: 8),
                        Text('Admin Dashboard'),
                      ],
                    ),
                  ),
                );
              }

              menuItems.add(const PopupMenuDivider());
              menuItems.add(
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              );

              return menuItems;
            },
          )
        else
            Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: OutlinedButton.icon(
              onPressed: () {
                context.go('/login');
              },
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text('Login'),
            ),
          ),
      ],
    );
  }
}
