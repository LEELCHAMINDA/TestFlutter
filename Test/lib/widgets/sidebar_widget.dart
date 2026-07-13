import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import 'print_products_widget.dart';
import 'product_list_widget.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key, required this.onMenuTap});

  final void Function(String title, {Widget? child}) onMenuTap;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      color: Colors.white,
      width: isMobile ? double.infinity : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Container(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 12),
          child: const Row(
            children: [
              Icon(Icons.inventory_2, color: Color(0xFF1565C0), size: 24),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Product Manager',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Color(0xFF1565C0)),
                ),
              ),
            ],
          ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              'MODULES',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          _SidebarItem(
            icon: Icons.inventory_2_outlined,
            title: 'Products',
            onTap: () => onMenuTap('Products', child: const ProductListWidget()),
          ),
          _SidebarItem(
            icon: Icons.print_outlined,
            title: 'Print Products',
            onTap: () => onMenuTap('Print Products', child: const PrintProductsWidget()),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'OTHERS',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          _SidebarItem(
            icon: Icons.article_outlined,
            title: 'Test',
            onTap: () => onMenuTap('Test'),
          ),
          _SidebarItem(
            icon: Icons.article_outlined,
            title: 'Test 1',
            onTap: () => onMenuTap('Test 1'),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
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
}
