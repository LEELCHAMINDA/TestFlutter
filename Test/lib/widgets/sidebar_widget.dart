import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/responsive.dart';
import 'print_products_widget.dart';
import 'product_list_widget.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({
    super.key,
    required this.onMenuTap,
    this.windowMenuItems = const [],
    this.onToggleTheme,
    this.themeMode,
  });

  final void Function(String title, {Widget? child}) onMenuTap;
  final List<SidebarMenuItem?> windowMenuItems;
  final VoidCallback? onToggleTheme;
  final ThemeMode? themeMode;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final Map<String, bool> _expanded = {
    'MODULES': true,
    'OTHERS': true,
    'WINDOW': true,
  };

  void _toggle(String key) {
    setState(() => _expanded[key] = !_expanded[key]!);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      width: isMobile ? double.infinity : null,
      child: ListView(
        padding: EdgeInsets.only(
          top: isMobile ? MediaQuery.of(context).padding.top : 0,
        ),
        children: [
          if (isMobile)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary, size: 24),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Product Manager',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          _TreeSection(
            title: 'MODULES',
            expanded: _expanded['MODULES']!,
            onTap: () => _toggle('MODULES'),
            children: [
              _SidebarItem(
                icon: Icons.inventory_2_outlined,
                title: 'Products',
                onTap: () => widget.onMenuTap('Products', child: const ProductListWidget()),
              ),
              _SidebarItem(
                icon: Icons.print_outlined,
                title: 'Print Products',
                onTap: () => widget.onMenuTap('Print Products', child: const PrintProductsWidget()),
              ),
            ],
          ),
          _TreeSection(
            title: 'OTHERS',
            expanded: _expanded['OTHERS']!,
            onTap: () => _toggle('OTHERS'),
            children: [
              _SidebarItem(
                icon: Icons.article_outlined,
                title: 'Test',
                onTap: () => widget.onMenuTap('Test'),
              ),
              _SidebarItem(
                icon: Icons.article_outlined,
                title: 'Test 1',
                onTap: () => widget.onMenuTap('Test 1'),
              ),
            ],
          ),
          if (widget.windowMenuItems.isNotEmpty)
            _TreeSection(
              title: 'WINDOW',
              expanded: _expanded['WINDOW']!,
              onTap: () => _toggle('WINDOW'),
              children: [
                ...widget.windowMenuItems.map((item) {
                  if (item == null) {
                    return const Divider(height: 1, indent: 16, endIndent: 16);
                  }
                  return _SidebarItem(
                    icon: item.icon,
                    title: item.label,
                    onTap: item.onTap ?? () {},
                    enabled: item.onTap != null,
                    isChecked: item.isChecked,
                  );
                }),
              ],
            ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _UserSection(onToggleTheme: widget.onToggleTheme, themeMode: widget.themeMode),
        ],
      ),
    );
  }
}

class _TreeSection extends StatelessWidget {
  const _TreeSection({
    required this.title,
    required this.expanded,
    required this.onTap,
    required this.children,
  });

  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          ...children.map((child) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: child,
          )),
      ],
    );
  }
}

class SidebarMenuItem {
  SidebarMenuItem(this.label, this.icon, this.onTap, {this.isChecked = false});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isChecked;
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isChecked = false,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isChecked;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: enabled ? Colors.grey.shade600 : Colors.grey.shade400),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: enabled ? Colors.grey.shade800 : Colors.grey.shade400,
                    ),
                  ),
                ),
                if (isChecked) Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserSection extends StatelessWidget {
  const _UserSection({this.onToggleTheme, this.themeMode});

  final VoidCallback? onToggleTheme;
  final ThemeMode? themeMode;

  IconData _themeIcon() => switch (themeMode) {
    ThemeMode.dark => Icons.dark_mode,
    ThemeMode.light => Icons.light_mode,
    _ => Icons.brightness_auto,
  };

  String _themeLabel() => switch (themeMode) {
    ThemeMode.dark => 'Dark Mode',
    ThemeMode.light => 'Light Mode',
    _ => 'System Theme',
  };

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  (user?.username ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.username ?? 'Unknown',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      user?.email ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (onToggleTheme != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onToggleTheme,
                icon: Icon(_themeIcon(), size: 16),
                label: Text(_themeLabel(), style: const TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          if (onToggleTheme != null) const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await context.read<AuthProvider>().logout();
                }
              },
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Sign Out', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
