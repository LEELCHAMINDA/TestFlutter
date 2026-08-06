import 'package:flutter/widgets.dart';

import '../models/operation_result.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/product_api_service.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider({ProductApiService? apiService, AuthService? authService})
      : _apiService = apiService ?? ProductApiService() {
    if (authService != null) {
      _apiService.setAuthHeaders(() => authService.authHeaders);
    }
  }

  final ProductApiService _apiService;

  ProductApiService get apiService => _apiService;

  String _name = '';
  String _price = '';
  String _stock = '';
  String _description = '';

  List<Product> _products = [];
  Product? _currentProduct;
  Product? _priorProduct;
  int _priorIndex = 0;
  bool _isLoading = true;
  bool _isLoadingRecord = false;
  String? _error;
  int _currentIndex = 0;
  bool _isEditing = false;
  bool _isNewRecord = false;
  bool _isSaving = false;
  bool _isActive = true;

  List<Product> get products => _products;
  Product? get currentProduct => _currentProduct;
  bool get isLoading => _isLoading;
  bool get isLoadingRecord => _isLoadingRecord;
  String? get error => _error;
  int get currentIndex => _currentIndex;
  bool get isEditing => _isEditing;
  bool get isNewRecord => _isNewRecord;
  bool get isSaving => _isSaving;
  bool get isActive => _isActive;
  bool get canNavigate => _products.isNotEmpty && !_isEditing && !_isLoadingRecord;
  bool get isFirst => _currentIndex == 0;
  bool get isLast => _currentIndex == _products.length - 1;
  String get recordPosition => _products.isEmpty ? '0 / 0' : '${_currentIndex + 1} / ${_products.length}';

  String get name => _name;
  String get price => _price;
  String get stock => _stock;
  String get description => _description;

  void setName(String value) {
    _name = value;
  }

  void setPrice(String value) {
    _price = value;
  }

  void setStock(String value) {
    _stock = value;
  }

  void setDescription(String value) {
    _description = value;
  }

  void setActive(bool value) {
    _isActive = value;
    notifyListeners();
  }

  void _loadCurrentRecord() {
    if (_currentProduct == null) {
      _name = '';
      _price = '';
      _stock = '';
      _description = '';
      _isActive = true;
      notifyListeners();
      return;
    }
    _name = _currentProduct!.name ?? '';
    _price = _currentProduct!.price.toStringAsFixed(2);
    _stock = _currentProduct!.stock.toString();
    _description = _currentProduct!.description ?? '';
    _isActive = _currentProduct!.isActive;
    notifyListeners();
  }

  void _selectProductAtIndex(int index) {
    if (index < 0 || index >= _products.length) return;
    _currentProduct = _products[index];
    _currentIndex = index;
    _isLoadingRecord = false;
    _loadCurrentRecord();
  }

  Future<OperationResult> fetchProducts() async {
    try {
      _products = await _apiService.getAllProducts();
      _isLoading = false;
      _error = null;
      if (_products.isNotEmpty) {
        if (_currentIndex >= _products.length) _currentIndex = _products.length - 1;
        _selectProductAtIndex(_currentIndex);
      } else {
        _currentProduct = null;
        _loadCurrentRecord();
      }
      return const OperationResult(true, 'Products loaded');
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return OperationResult(false, _error!);
    }
  }

  void goToFirst() {
    if (_products.isEmpty || _currentIndex == 0) return;
    _isEditing = false;
    _isNewRecord = false;
    _selectProductAtIndex(0);
  }

  void goToPrevious() {
    if (_products.isEmpty || _currentIndex == 0) return;
    _isEditing = false;
    _isNewRecord = false;
    _selectProductAtIndex(_currentIndex - 1);
  }

  void goToNext() {
    if (_products.isEmpty || _currentIndex == _products.length - 1) return;
    _isEditing = false;
    _isNewRecord = false;
    _selectProductAtIndex(_currentIndex + 1);
  }

  void goToLast() {
    if (_products.isEmpty || _currentIndex == _products.length - 1) return;
    _isEditing = false;
    _isNewRecord = false;
    _selectProductAtIndex(_products.length - 1);
  }

  void addNew() {
    _priorProduct = _currentProduct;
    _priorIndex = _currentIndex;
    _isNewRecord = true;
    _isEditing = true;
    _currentProduct = null;
    _name = '';
    _price = '';
    _stock = '';
    _description = '';
    _isActive = true;
    notifyListeners();
  }

  void editRecord() {
    _isEditing = true;
    _isNewRecord = false;
    notifyListeners();
  }

  void undoChanges() {
    _isEditing = false;
    _isNewRecord = false;
    if (_priorProduct != null) {
      _currentProduct = _priorProduct;
      _currentIndex = _priorIndex.clamp(0, _products.length - 1);
      _priorProduct = null;
      _loadCurrentRecord();
    } else if (_products.isNotEmpty && _currentProduct != null) {
      _loadCurrentRecord();
    } else {
      notifyListeners();
    }
  }

  void navigateToIndex(int index) {
    _selectProductAtIndex(index);
  }

  Future<List<Product>> fetchAllProducts() async {
    return await _apiService.getAllProducts();
  }

  Future<OperationResult> saveRecord() async {
    if (_isSaving) return const OperationResult(false, 'Already saving');

    if (_name.trim().isEmpty) {
      return const OperationResult(false, 'Product name is required');
    }

    _isSaving = true;
    notifyListeners();

    try {
      final isNew = _isNewRecord;

      final product = Product(
        id: isNew ? 0 : (_currentProduct?.id ?? 0),
        name: _name.trim(),
        price: double.tryParse(_price) ?? 0,
        description: _description.trim(),
        stock: int.tryParse(_stock) ?? 0,
        isActive: _isActive,
        createdDate: isNew ? DateTime.now() : (_currentProduct?.createdDate ?? DateTime.now()),
      );

      if (_isNewRecord) {
        final newId = await _apiService.createProduct(product);
        final created = product.copyWith(id: newId);
        _products.add(created);
        _isEditing = false;
        _isNewRecord = false;
        _isSaving = false;
        _currentIndex = _products.length - 1;
        _currentProduct = created;
        _loadCurrentRecord();
        return const OperationResult(true, 'Product created successfully');
      } else {
        final originalProduct = _currentProduct;
        _currentProduct = product;
        _isEditing = false;
        _isNewRecord = false;
        _isSaving = false;
        _loadCurrentRecord();

        try {
          await _apiService.updateProduct(product);
          _products[_currentIndex] = product;
          return const OperationResult(true, 'Product updated successfully');
        } catch (e) {
          _currentProduct = originalProduct;
          _loadCurrentRecord();
          return OperationResult(false, 'Error updating product: $e');
        }
      }
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      return OperationResult(false, 'Error: $e');
    }
  }

  Future<OperationResult> deleteRecord() async {
    if (_products.isEmpty) return const OperationResult(false, 'No products to delete');
    if (_currentIndex < 0 || _currentIndex >= _products.length) {
      return const OperationResult(false, 'Invalid record index');
    }

    final deletedProduct = _products[_currentIndex];
    final deletedId = deletedProduct.id;
    final deletedIndex = _currentIndex;

    _products.removeAt(deletedIndex);
    if (_currentIndex >= _products.length && _currentIndex > 0) {
      _currentIndex = _products.length - 1;
    }

    if (_products.isNotEmpty) {
      _selectProductAtIndex(_currentIndex);
    } else {
      _currentProduct = null;
      _loadCurrentRecord();
    }

    try {
      await _apiService.deleteProduct(deletedId);
      return const OperationResult(true, 'Product deleted successfully');
    } catch (e) {
      _products.insert(deletedIndex, deletedProduct);
      _selectProductAtIndex(deletedIndex);
      return OperationResult(false, 'Error deleting product: $e');
    }
  }
}
