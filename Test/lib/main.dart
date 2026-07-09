import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

String get apiBaseUrl {
  if (kIsWeb) return 'http://localhost:5148';
  if (Platform.isAndroid) return 'http://10.0.2.2:5148';
  return 'http://localhost:5148';
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MDIHomePage(),
    );
  }
}

class MDIHomePage extends StatefulWidget {
  const MDIHomePage({super.key});

  @override
  State<MDIHomePage> createState() => _MDIHomePageState();
}

class _MDIHomePageState extends State<MDIHomePage> {
  final List<_MDIWindow> _windows = [];
  int _windowIdCounter = 0;
  double _menuWidth = 200;
  bool _isMenuVisible = true;
  double _previousMenuWidth = 200;

  void _toggleMenu() {
    setState(() {
      if (_isMenuVisible) {
        _previousMenuWidth = _menuWidth;
        _menuWidth = 0;
      } else {
        _menuWidth = _previousMenuWidth;
      }
      _isMenuVisible = !_isMenuVisible;
    });
  }

  void _addWindow(String title, {Widget? child}) {
    setState(() {
      _windows.add(_MDIWindow(
        id: _windowIdCounter++,
        title: title,
        offset: Offset.zero,
        child: child,
        maximized: true,
        minimized: false,
      ));
    });
  }

  void _closeWindow(int id) {
    setState(() {
      _windows.removeWhere((w) => w.id == id);
    });
  }

  void _bringToFront(int id) {
    setState(() {
      final idx = _windows.indexWhere((w) => w.id == id);
      if (idx != -1) {
        final win = _windows.removeAt(idx);
        _windows.add(win);
      }
    });
  }

  void _toggleMaximize(int id) {
    setState(() {
      final win = _windows.firstWhere((w) => w.id == id);
      win.maximized = !win.maximized;
      win.minimized = false;
    });
  }

  void _minimizeWindow(int id) {
    setState(() {
      final win = _windows.firstWhere((w) => w.id == id);
      win.minimized = true;
    });
  }

  void _restoreWindow(int id) {
    setState(() {
      final win = _windows.firstWhere((w) => w.id == id);
      win.minimized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleWindows = _windows.where((w) => !w.minimized).toList();
    final minimizedWindows = _windows.where((w) => w.minimized).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: Icon(_isMenuVisible ? Icons.menu_open : Icons.menu),
          onPressed: _toggleMenu,
          tooltip: _isMenuVisible ? 'Hide Menu' : 'Show Menu',
        ),
        title: const Text('MDI Test'),
        actions: minimizedWindows.isNotEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: minimizedWindows.map((win) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: GestureDetector(
                          onTap: () => _restoreWindow(win.id),
                          child: Tooltip(
                            message: win.title,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.open_in_new, size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(win.title, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ]
            : [],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                if (_isMenuVisible)
                  SizedBox(
                    width: _menuWidth,
                    child: Material(
                      color: Colors.grey[200],
                      child: ListView(
                        padding: const EdgeInsets.all(8),
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
                            child: Text(
                              'Menu',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.article),
                            title: const Text('test'),
                            onTap: () => _addWindow('test'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.article),
                            title: const Text('test1'),
                            onTap: () => _addWindow('test1'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.inventory),
                            title: const Text('Products'),
                            onTap: () => _addWindow('Products', child: const ProductListWidget()),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isMenuVisible)
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _menuWidth = (_menuWidth + details.delta.dx).clamp(100.0, 500.0);
                          _previousMenuWidth = _menuWidth;
                        });
                      },
                      child: Container(
                        width: 6,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: visibleWindows.map((win) {
                          if (win.maximized) {
                            return Positioned.fill(
                              child: GestureDetector(
                                onTap: () => _bringToFront(win.id),
                                child: MDIWindowWidget(
                                  title: win.title,
                                  maximized: true,
                                  onClose: () => _closeWindow(win.id),
                                  onMaximize: () => _toggleMaximize(win.id),
                                  onMinimize: () => _minimizeWindow(win.id),
                                  child: win.child,
                                ),
                              ),
                            );
                          }
                          return Positioned(
                            left: win.offset.dx,
                            top: win.offset.dy,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  win.offset += details.delta;
                                });
                              },
                              onTap: () => _bringToFront(win.id),
                              child: MDIWindowWidget(
                                title: win.title,
                                maximized: false,
                                onClose: () => _closeWindow(win.id),
                                onMaximize: () => _toggleMaximize(win.id),
                                onMinimize: () => _minimizeWindow(win.id),
                                child: win.child,
                              ),
                            ),
                          );
                        }                        ).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MDIWindow {
  final int id;
  final String title;
  final Widget? child;
  Offset offset;
  bool maximized;
  bool minimized;

  _MDIWindow({
    required this.id,
    required this.title,
    required this.offset,
    this.child,
    this.maximized = true,
    this.minimized = false,
  });
}

class MDIWindowWidget extends StatelessWidget {
  final String title;
  final bool maximized;
  final VoidCallback onClose;
  final VoidCallback onMaximize;
  final VoidCallback onMinimize;
  final Widget? child;

  const MDIWindowWidget({
    super.key,
    required this.title,
    required this.maximized,
    required this.onClose,
    required this.onMaximize,
    required this.onMinimize,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: maximized ? BorderRadius.zero : BorderRadius.circular(8),
      child: Container(
        width: maximized ? double.infinity : 400,
        height: maximized ? double.infinity : 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: maximized ? BorderRadius.zero : BorderRadius.circular(8),
          border: maximized ? null : Border.all(color: Colors.grey[400]!),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: maximized
                    ? BorderRadius.zero
                    : const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: onMinimize,
                    child: const Icon(Icons.minimize, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onMaximize,
                    child: Icon(
                      maximized ? Icons.filter_none : Icons.crop_square,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: child ?? Center(
                child: Text('Content of $title', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Product {
  final int id;
  final String? name;
  final double price;
  final String? description;
  final int stock;
  final bool isActive;
  final DateTime createdDate;

  Product({
    required this.id,
    this.name,
    required this.price,
    this.description,
    required this.stock,
    required this.isActive,
    required this.createdDate,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'],
      stock: json['stock'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdDate: DateTime.tryParse(json['createdDate'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'stock': stock,
      'isActive': isActive,
      'createdDate': createdDate.toIso8601String(),
    };
  }
}

class ProductListWidget extends StatefulWidget {
  const ProductListWidget({super.key});

  @override
  State<ProductListWidget> createState() => _ProductListWidgetState();
}

class _ProductListWidgetState extends State<ProductListWidget> {
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/products'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _products = data.map((json) => Product.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load products: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(int id) async {
    try {
      final response = await http.delete(Uri.parse('$apiBaseUrl/api/products/$id'));
      if (response.statusCode == 204) {
        _fetchProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(product.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showProductForm({Product? product}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ProductFormDialog(product: product),
    );
    if (result == true) {
      _fetchProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetchProducts();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Products',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showProductForm(),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _fetchProducts();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Stock')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _products.map((product) {
                  return DataRow(cells: [
                    DataCell(Text(product.id.toString())),
                    DataCell(Text(product.name ?? '')),
                    DataCell(Text('\$${product.price.toStringAsFixed(2)}')),
                    DataCell(Text(product.stock.toString())),
                    DataCell(Text(product.description ?? '')),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showProductForm(product: product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(product),
                          ),
                        ],
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductFormDialog extends StatefulWidget {
  final Product? product;

  const ProductFormDialog({super.key, this.product});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '0');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _isActive = widget.product?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.product != null;

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final product = Product(
        id: widget.product?.id ?? 0,
        name: _nameController.text,
        price: double.parse(_priceController.text),
        description: _descriptionController.text,
        stock: int.parse(_stockController.text),
        isActive: _isActive,
        createdDate: widget.product?.createdDate ?? DateTime.now(),
      );

      http.Response response;
      if (isEditing) {
        response = await http.put(
          Uri.parse('$apiBaseUrl/api/products/${product.id}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(product.toJson()),
        );
      } else {
        response = await http.post(
          Uri.parse('$apiBaseUrl/api/products'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(product.toJson()),
        );
      }

      if (mounted) {
        if (response.statusCode == 201 || response.statusCode == 204) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter stock quantity';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid integer';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveProduct,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
