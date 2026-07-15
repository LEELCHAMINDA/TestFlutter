import 'package:flutter/widgets.dart';

import '../models/operation_result.dart';
import '../models/product.dart';
import '../services/product_api_service.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider({ProductApiService? apiService})
      : _apiService = apiService ?? ProductApiService();

  final ProductApiService _apiService;

  ProductApiService get apiService => _apiService;

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final descriptionController = TextEditingController();

  List<int> _productIds = [];
  Product? _currentProduct;
  bool _isLoading = true;
  bool _isLoadingRecord = false;
  String? _error;
  int _currentIndex = 0;
  bool _isEditing = false;
  bool _isNewRecord = false;
  bool _isSaving = false;
  bool _isActive = true;

  List<int> get productIds => _productIds;
  Product? get currentProduct => _currentProduct;
  bool get isLoading => _isLoading;
  bool get isLoadingRecord => _isLoadingRecord;
  String? get error => _error;
  int get currentIndex => _currentIndex;
  bool get isEditing => _isEditing;
  bool get isNewRecord => _isNewRecord;
  bool get isSaving => _isSaving;
  bool get isActive => _isActive;
  bool get canNavigate => _productIds.isNotEmpty && !_isEditing && !_isLoadingRecord;
  bool get isFirst => _currentIndex == 0;
  bool get isLast => _currentIndex == _productIds.length - 1;
  String get recordPosition => _productIds.isEmpty ? '0 / 0' : '${_currentIndex + 1} / ${_productIds.length}';

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    descriptionController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _loadCurrentRecord() {
    if (_currentProduct == null) {
      nameController.clear();
      priceController.clear();
      stockController.clear();
      descriptionController.clear();
      _isActive = true;
      notifyListeners();
      return;
    }
    nameController.text = _currentProduct!.name ?? '';
    priceController.text = _currentProduct!.price.toStringAsFixed(2);
    stockController.text = _currentProduct!.stock.toString();
    descriptionController.text = _currentProduct!.description ?? '';
    _isActive = _currentProduct!.isActive;
    notifyListeners();
  }

  Future<void> _fetchProductAtIndex(int index) async {
    if (index < 0 || index >= _productIds.length) return;
    _isLoadingRecord = true;
    notifyListeners();

    try {
      final id = _productIds[index];
      _currentProduct = await _apiService.getProductById(id);
      _currentIndex = index;
      _isLoadingRecord = false;
      _loadCurrentRecord();
    } catch (e) {
      _isLoadingRecord = false;
      _currentProduct = null;
      _currentIndex = index;
      _loadCurrentRecord();
    }
  }

  Future<OperationResult> fetchProducts() async {
    try {
      _productIds = await _apiService.getAllProductIds();
      _isLoading = false;
      _error = null;
      if (_productIds.isNotEmpty && _currentIndex >= _productIds.length) {
        _currentIndex = _productIds.length - 1;
      }
      if (_productIds.isNotEmpty) {
        await _fetchProductAtIndex(_currentIndex);
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
    if (_productIds.isEmpty || _currentIndex == 0) return;
    _isEditing = false;
    _isNewRecord = false;
    _fetchProductAtIndex(0);
  }

  void goToPrevious() {
    if (_productIds.isEmpty || _currentIndex == 0) return;
    _isEditing = false;
    _isNewRecord = false;
    _fetchProductAtIndex(_currentIndex - 1);
  }

  void goToNext() {
    if (_productIds.isEmpty || _currentIndex == _productIds.length - 1) return;
    _isEditing = false;
    _isNewRecord = false;
    _fetchProductAtIndex(_currentIndex + 1);
  }

  void goToLast() {
    if (_productIds.isEmpty || _currentIndex == _productIds.length - 1) return;
    _isEditing = false;
    _isNewRecord = false;
    _fetchProductAtIndex(_productIds.length - 1);
  }

  void addNew() {
    _isNewRecord = true;
    _isEditing = true;
    _currentProduct = null;
    nameController.clear();
    priceController.clear();
    stockController.clear();
    descriptionController.clear();
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
    if (_productIds.isNotEmpty && _currentProduct != null) {
      _loadCurrentRecord();
    } else {
      notifyListeners();
    }
  }

  void setActive(bool value) {
    _isActive = value;
    notifyListeners();
  }

  void navigateToIndex(int index) {
    _fetchProductAtIndex(index);
  }

  Future<List<Product>> fetchAllProducts() async {
    try {
      return await _apiService.searchProducts('');
    } catch (e) {
      return [];
    }
  }

  Future<OperationResult> saveRecord() async {
    if (_isSaving) return const OperationResult(false, 'Already saving');
    
    if (nameController.text.trim().isEmpty) {
      return const OperationResult(false, 'Product name is required');
    }
    
    _isSaving = true;
    notifyListeners();

    try {
      final isNew = _isNewRecord;
      
      final product = Product(
        id: isNew ? 0 : (_currentProduct?.id ?? 0),
        name: nameController.text.trim(),
        price: double.tryParse(priceController.text) ?? 0,
        description: descriptionController.text.trim(),
        stock: int.tryParse(stockController.text) ?? 0,
        isActive: _isActive,
        createdDate: isNew ? DateTime.now() : (_currentProduct?.createdDate ?? DateTime.now()),
      );

      if (_isNewRecord) {
        _isEditing = false;
        _isNewRecord = false;
        _isSaving = false;
        notifyListeners();

        try {
          final newId = await _apiService.createProduct(product);
          _productIds.add(newId);
          await _fetchProductAtIndex(_productIds.length - 1);
          return const OperationResult(true, 'Product created successfully');
        } catch (e) {
          notifyListeners();
          return OperationResult(false, 'Error creating product: $e');
        }
      } else {
        final originalProduct = _currentProduct;
        _currentProduct = product;
        _isEditing = false;
        _isNewRecord = false;
        _isSaving = false;
        _loadCurrentRecord();

        try {
          await _apiService.updateProduct(product);
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
    if (_productIds.isEmpty) return const OperationResult(false, 'No products to delete');
    if (_currentIndex < 0 || _currentIndex >= _productIds.length) {
      return const OperationResult(false, 'Invalid record index');
    }

    final deletedId = _productIds[_currentIndex];
    final deletedIndex = _currentIndex;
    
    _productIds.removeAt(deletedIndex);
    if (_currentIndex >= _productIds.length && _currentIndex > 0) {
      _currentIndex = _productIds.length - 1;
    }
    
    if (_productIds.isNotEmpty) {
      await _fetchProductAtIndex(_currentIndex);
    } else {
      _currentProduct = null;
      _loadCurrentRecord();
    }

    try {
      await _apiService.deleteProduct(deletedId);
      return const OperationResult(true, 'Product deleted successfully');
    } catch (e) {
      _productIds.insert(deletedIndex, deletedId);
      await _fetchProductAtIndex(deletedIndex);
      return OperationResult(false, 'Error deleting product: $e');
    }
  }
}
