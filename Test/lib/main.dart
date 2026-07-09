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
  int _currentIndex = 0;
  bool _isEditing = false;
  bool _isNewRecord = false;

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _stockController = TextEditingController();
    _descriptionController = TextEditingController();
    _isActive = true;
    _fetchProducts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/products'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _products = data.map((json) => Product.fromJson(json)).toList();
          _isLoading = false;
          if (_products.isNotEmpty) {
            _loadCurrentRecord();
          }
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

  void _loadCurrentRecord() {
    if (_products.isEmpty) return;
    final product = _products[_currentIndex];
    _nameController.text = product.name ?? '';
    _priceController.text = product.price.toString();
    _stockController.text = product.stock.toString();
    _descriptionController.text = product.description ?? '';
    _isActive = product.isActive;
  }

  void _goToFirst() {
    if (_products.isEmpty) return;
    setState(() {
      _currentIndex = 0;
      _isEditing = false;
      _isNewRecord = false;
      _loadCurrentRecord();
    });
  }

  void _goToPrevious() {
    if (_products.isEmpty || _currentIndex == 0) return;
    setState(() {
      _currentIndex--;
      _isEditing = false;
      _isNewRecord = false;
      _loadCurrentRecord();
    });
  }

  void _goToNext() {
    if (_products.isEmpty || _currentIndex == _products.length - 1) return;
    setState(() {
      _currentIndex++;
      _isEditing = false;
      _isNewRecord = false;
      _loadCurrentRecord();
    });
  }

  void _goToLast() {
    if (_products.isEmpty) return;
    setState(() {
      _currentIndex = _products.length - 1;
      _isEditing = false;
      _isNewRecord = false;
      _loadCurrentRecord();
    });
  }

  void _addNew() {
    setState(() {
      _isNewRecord = true;
      _isEditing = true;
      _nameController.clear();
      _priceController.clear();
      _stockController.clear();
      _descriptionController.clear();
      _isActive = true;
    });
  }

  void _editRecord() {
    setState(() {
      _isEditing = true;
      _isNewRecord = false;
    });
  }

  void _undoChanges() {
    setState(() {
      _isEditing = false;
      _isNewRecord = false;
      if (_products.isNotEmpty) {
        _loadCurrentRecord();
      }
    });
  }

  void _showSearchDialog() {
    String searchQuery = '';
    List<Product> filteredProducts = List.from(_products);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Search Products'),
              content: SizedBox(
                width: 400,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Search by Name',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        searchQuery = value.toLowerCase();
                        setDialogState(() {
                          filteredProducts = _products
                              .where((p) => (p.name ?? '').toLowerCase().contains(searchQuery))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? const Center(child: Text('No products found'))
                          : ListView.builder(
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                return ListTile(
                                  title: Text(product.name ?? ''),
                                  subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                                  trailing: Text('Stock: ${product.stock}'),
                                  onTap: () {
                                    final originalIndex = _products.indexWhere((p) => p.id == product.id);
                                    if (originalIndex != -1) {
                                      setState(() {
                                        _currentIndex = originalIndex;
                                        _isEditing = false;
                                        _isNewRecord = false;
                                        _loadCurrentRecord();
                                      });
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

  Future<void> _saveRecord() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    try {
      final product = Product(
        id: _isNewRecord ? 0 : _products[_currentIndex].id,
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        description: _descriptionController.text,
        stock: int.tryParse(_stockController.text) ?? 0,
        isActive: _isActive,
        createdDate: _isNewRecord ? DateTime.now() : _products[_currentIndex].createdDate,
      );

      http.Response response;
      if (_isNewRecord) {
        response = await http.post(
          Uri.parse('$apiBaseUrl/api/products'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(product.toJson()),
        );
      } else {
        response = await http.put(
          Uri.parse('$apiBaseUrl/api/products/${product.id}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(product.toJson()),
        );
      }

      if (response.statusCode == 201 || response.statusCode == 204) {
        setState(() {
          _isEditing = false;
          _isNewRecord = false;
        });
        await _fetchProducts();
      } else {
        if (mounted) {
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
    }
  }

  Future<void> _deleteRecord() async {
    if (_products.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${_products[_currentIndex].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await http.delete(
          Uri.parse('$apiBaseUrl/api/products/${_products[_currentIndex].id}'),
        );
        if (response.statusCode == 204) {
          if (_currentIndex >= _products.length - 1 && _currentIndex > 0) {
            _currentIndex--;
          }
          await _fetchProducts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting product: $e')),
          );
        }
      }
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

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              _buildIconButton(Icons.first_page, 'First', _goToFirst, _products.isEmpty || _currentIndex == 0),
              _buildIconButton(Icons.chevron_left, 'Previous', _goToPrevious, _products.isEmpty || _currentIndex == 0),
              _buildIconButton(Icons.chevron_right, 'Next', _goToNext, _products.isEmpty || _currentIndex == _products.length - 1),
              _buildIconButton(Icons.last_page, 'Last', _goToLast, _products.isEmpty || _currentIndex == _products.length - 1),
              const SizedBox(width: 16),
              _buildActionButton('Add New', Colors.blue, Icons.add, _addNew),
              const SizedBox(width: 8),
              _buildActionButton('Edit', Colors.grey[700]!, Icons.edit, _products.isEmpty ? null : _editRecord),
              const SizedBox(width: 8),
              _buildActionButton('Delete', Colors.red, Icons.delete, _products.isEmpty ? null : _deleteRecord),
              const SizedBox(width: 8),
              _buildActionButton('Save', Colors.green, Icons.save, _isEditing ? _saveRecord : null),
              const SizedBox(width: 8),
              _buildActionButton('Undo', Colors.grey[600]!, Icons.undo, _isEditing ? _undoChanges : null),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _showSearchDialog,
                tooltip: 'Search',
              ),
              const SizedBox(width: 8),
              Text(
                'Product ${_products.isEmpty ? 0 : _currentIndex + 1} of ${_products.length}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSection('PRODUCT INFORMATION', [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField('Name *', _nameController, enabled: _isEditing),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField('Price', _priceController, enabled: _isEditing, prefix: '\$'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField('Stock', _stockController, enabled: _isEditing),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSwitchField('Active', _isActive, _isEditing, (value) {
                          setState(() {
                            _isActive = value;
                          });
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('Description', _descriptionController, enabled: _isEditing, maxLines: 3),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, String tooltip, VoidCallback? onPressed, bool disabled) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: disabled ? null : onPressed,
      tooltip: tooltip,
      color: Colors.grey[700],
    );
  }

  Widget _buildActionButton(String label, Color color, IconData icon, VoidCallback? onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null ? color : Colors.grey[300],
        foregroundColor: onPressed != null ? Colors.white : Colors.grey[600],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool enabled = true, int maxLines = 1, String? prefix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: label.contains('*') ? Colors.red : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            enabledBorder: const OutlineInputBorder(),
            disabledBorder: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: !enabled,
            fillColor: enabled ? null : Colors.grey[100],
            prefixText: prefix,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchField(String label, bool value, bool enabled, ValueChanged<bool> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
        const SizedBox(height: 4),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}
