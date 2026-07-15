import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/responsive.dart';
import 'common_widgets.dart';

class ProductListWidget extends StatelessWidget {
  const ProductListWidget({super.key});

  void _showTopNotification(BuildContext context, String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 16,
        right: 16,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8, minWidth: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade600 : Colors.green.shade600,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => entry.remove(),
                  child: const Icon(Icons.close, color: Colors.white70, size: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }

  void _showSearchDialog(BuildContext context, ProductProvider provider) {
    String searchQuery = '';
    List<Product> searchResults = [];
    bool isSearching = false;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth * 0.85).clamp(300.0, 500.0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.search, size: 20),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text('Search Products', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              content: SizedBox(
                width: dialogWidth,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search by name...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (value) async {
                        searchQuery = value;
                        if (value.trim().isEmpty) {
                          setDialogState(() {
                            searchResults = [];
                            isSearching = false;
                          });
                          return;
                        }
                        setDialogState(() {
                          isSearching = true;
                        });
                        await Future.delayed(const Duration(milliseconds: 300));
                        if (searchQuery != value) return;
                        try {
                          final results = await provider.apiService.searchProducts(value);
                          if (searchQuery == value && context.mounted) {
                            setDialogState(() {
                              searchResults = results;
                              isSearching = false;
                            });
                          }
                        } catch (e) {
                          if (searchQuery == value && context.mounted) {
                            setDialogState(() {
                              searchResults = [];
                              isSearching = false;
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isSearching
                          ? const Center(child: CircularProgressIndicator())
                          : searchResults.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.search_off, size: 40, color: Colors.grey.shade300),
                                      const SizedBox(height: 8),
                                      Text(
                                        searchQuery.isEmpty ? 'Type to search...' : 'No products found',
                                        style: TextStyle(color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: searchResults.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final product = searchResults[index];
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                      leading: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
                                        child: Text(
                                          (product.name?.isNotEmpty == true ? product.name![0] : '?').toUpperCase(),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1565C0)),
                                        ),
                                      ),
                                      title: Text(
                                        product.name ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: Text(
                                        '\$${product.price.toStringAsFixed(2)}',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: product.isActive ? Colors.green.shade50 : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Stock: ${product.stock}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: product.isActive ? Colors.green.shade700 : Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        final originalIndex = provider.productIds.indexOf(product.id);
                                        if (originalIndex != -1) {
                                          provider.navigateToIndex(originalIndex);
                                        }
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleDelete(BuildContext context, ProductProvider provider) async {
    if (provider.productIds.isEmpty) return;
    final product = provider.currentProduct;
    if (product == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Flexible(
              child: Text('Delete Product', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await provider.deleteRecord();
      if (context.mounted) {
        _showTopNotification(context, result.message, isError: !result.success);
      }
    }
  }

  Future<void> _handleSave(BuildContext context, ProductProvider provider, GlobalKey<FormState> formKey) async {
    if (provider.isSaving) return;
    if (formKey.currentState?.validate() != true) return;

    final result = await provider.saveRecord();
    if (context.mounted) {
      _showTopNotification(context, result.message, isError: !result.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final formKey = GlobalKey<FormState>();

    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading products...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => provider.fetchProducts(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (provider.productIds.isEmpty) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.all(Responsive.isMobile(context) ? 24 : 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No Products Found',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get started by adding your first product.',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => provider.addNew(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Product'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRect(
      child: Column(
        children: [
          _buildToolbar(context, provider, formKey),
          Expanded(child: _buildForm(context, provider, formKey)),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, ProductProvider provider, GlobalKey<FormState> formKey) {
    final bool hasData = provider.productIds.isNotEmpty;
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      clipBehavior: Clip.hardEdge,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            NavIconButton(Icons.first_page, () => provider.goToFirst(), !provider.canNavigate || provider.isFirst, 'First'),
            NavIconButton(Icons.chevron_left, () => provider.goToPrevious(), !provider.canNavigate || provider.isFirst, 'Previous'),
            NavIconButton(Icons.chevron_right, () => provider.goToNext(), !provider.canNavigate || provider.isLast, 'Next'),
            NavIconButton(Icons.last_page, () => provider.goToLast(), !provider.canNavigate || provider.isLast, 'Last'),
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.grey.shade300,
            ),
            ActionChipButton(
              label: 'Add',
              icon: Icons.add,
              color: const Color(0xFF1565C0),
              onPressed: provider.isEditing ? null : () => provider.addNew(),
            ),
            const SizedBox(width: 6),
            ActionChipButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              color: Colors.grey.shade700,
              onPressed: (!hasData || provider.isEditing) ? null : () => provider.editRecord(),
            ),
            const SizedBox(width: 6),
            ActionChipButton(
              label: 'Delete',
              icon: Icons.delete_outline,
              color: Colors.red.shade600,
              onPressed: (!hasData || provider.isEditing) ? null : () => _handleDelete(context, provider),
            ),
            const SizedBox(width: 6),
            ActionChipButton(
              label: provider.isSaving ? 'Saving...' : 'Save',
              icon: provider.isSaving ? Icons.hourglass_top : Icons.check,
              color: Colors.green.shade600,
              onPressed: (provider.isEditing && !provider.isSaving) ? () => _handleSave(context, provider, formKey) : null,
            ),
            const SizedBox(width: 6),
            ActionChipButton(
              label: 'Undo',
              icon: Icons.undo,
              color: Colors.orange.shade700,
              onPressed: provider.isEditing ? () => provider.undoChanges() : null,
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(Icons.search, size: 20, color: Colors.grey.shade600),
              onPressed: () => _showSearchDialog(context, provider),
              tooltip: 'Search',
              splashRadius: 18,
            ),
            if (!isMobile) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  provider.recordPosition,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, ProductProvider provider, GlobalKey<FormState> formKey) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 12.0 : 20.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              clipBehavior: Clip.hardEdge,
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 14 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2, size: 20, color: Color(0xFF1565C0)),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Product Information',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (isMobile) ...[
                      _buildField(
                        label: 'Name',
                        child: TextFormField(
                          controller: provider.nameController,
                          enabled: provider.isEditing,
                          validator: (value) {
                            if (provider.isEditing && (value == null || value.trim().isEmpty)) {
                              return 'Required';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(hintText: 'Enter product name'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        label: 'Price',
                        child: TextFormField(
                          controller: provider.priceController,
                          enabled: provider.isEditing,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (provider.isEditing && (value == null || value.trim().isEmpty)) {
                              return 'Required';
                            }
                            if (provider.isEditing) {
                              final num = double.tryParse(value!);
                              if (num == null) return 'Invalid number';
                              if (num < 0) return 'Must be positive';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            prefixText: r'$ ',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        label: 'Stock',
                        child: TextFormField(
                          controller: provider.stockController,
                          enabled: provider.isEditing,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (provider.isEditing && (value == null || value.trim().isEmpty)) {
                              return 'Required';
                            }
                            if (provider.isEditing) {
                              final num = int.tryParse(value!);
                              if (num == null) return 'Invalid integer';
                              if (num < 0) return 'Must be positive';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(hintText: '0'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        label: 'Status',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                provider.isActive ? Icons.check_circle : Icons.cancel,
                                size: 16,
                                color: provider.isActive ? Colors.green.shade600 : Colors.red.shade400,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                provider.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const Spacer(),
                              if (provider.isEditing)
                                Switch(
                                  value: provider.isActive,
                                  onChanged: (value) => provider.setActive(value),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'Name',
                              child: TextFormField(
                                controller: provider.nameController,
                                enabled: provider.isEditing,
                                validator: (value) {
                                  if (provider.isEditing && (value == null || value.trim().isEmpty)) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                                decoration: const InputDecoration(hintText: 'Enter product name'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'Price',
                              child: TextFormField(
                                controller: provider.priceController,
                                enabled: provider.isEditing,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (provider.isEditing && (value == null || value.trim().isEmpty)) {
                                    return 'Required';
                                  }
                                  if (provider.isEditing) {
                                    final num = double.tryParse(value!);
                                    if (num == null) return 'Invalid number';
                                    if (num < 0) return 'Must be positive';
                                  }
                                  return null;
                                },
                                decoration: const InputDecoration(
                                  hintText: '0.00',
                                  prefixText: r'$ ',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'Stock',
                              child: TextFormField(
                                controller: provider.stockController,
                                enabled: provider.isEditing,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (provider.isEditing && (value == null || value.trim().isEmpty)) {
                                    return 'Required';
                                  }
                                  if (provider.isEditing) {
                                    final num = int.tryParse(value!);
                                    if (num == null) return 'Invalid integer';
                                    if (num < 0) return 'Must be positive';
                                  }
                                  return null;
                                },
                                decoration: const InputDecoration(hintText: '0'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'Status',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        provider.isActive ? Icons.check_circle : Icons.cancel,
                                        size: 16,
                                        color: provider.isActive ? Colors.green.shade600 : Colors.red.shade400,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        provider.isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (provider.isEditing)
                                        Switch(
                                          value: provider.isActive,
                                          onChanged: (value) => provider.setActive(value),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                    ],
                                  ),
                                ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Description',
                      child: TextFormField(
                        controller: provider.descriptionController,
                        enabled: provider.isEditing,
                        maxLines: isMobile ? 2 : 3,
                        decoration: const InputDecoration(hintText: 'Enter product description (optional)'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
