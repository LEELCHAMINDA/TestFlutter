import 'package:flutter/widgets.dart';

import '../models/operation_result.dart';
import '../models/product.dart';
import '../services/product_api_service.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider({ProductApiService? apiService})
      : _apiService = apiService ?? ProductApiService();

  final ProductApiService _apiService;

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final descriptionController = TextEditingController();

  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  bool _isEditing = false;
  bool _isNewRecord = false;
  bool _isSaving = false;
  bool _isActive = true;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentIndex => _currentIndex;
  bool get isEditing => _isEditing;
  bool get isNewRecord => _isNewRecord;
  bool get isSaving => _isSaving;
  bool get isActive => _isActive;
  Product? get currentProduct => _products.isNotEmpty ? _products[_currentIndex] : null;
  bool get canNavigate => _products.isNotEmpty && !_isEditing;
  String get recordPosition => _products.isEmpty ? '0 / 0' : '${_currentIndex + 1} / ${_products.length}';
  bool get isFirst => _currentIndex == 0;
  bool get isLast => _currentIndex == _products.length - 1;

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    descriptionController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void loadCurrentRecord() {
    if (_products.isEmpty) return;
    final product = _products[_currentIndex];
    nameController.text = product.name ?? '';
    priceController.text = product.price.toStringAsFixed(2);
    stockController.text = product.stock.toString();
    descriptionController.text = product.description ?? '';
    _isActive = product.isActive;
    notifyListeners();
  }

  Future<OperationResult> fetchProducts() async {
    try {
      _products = await _apiService.getAllProducts();
      _isLoading = false;
      _error = null;
      if (_products.isNotEmpty && _currentIndex >= _products.length) {
        _currentIndex = _products.length - 1;
      }
      if (_products.isNotEmpty) {
        loadCurrentRecord();
      }
      notifyListeners();
      return const OperationResult(true, 'Products loaded');
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return OperationResult(false, _error!);
    }
  }

  void goToFirst() {
    if (_products.isEmpty) return;
    _currentIndex = 0;
    _isEditing = false;
    _isNewRecord = false;
    loadCurrentRecord();
  }

  void goToPrevious() {
    if (_products.isEmpty || _currentIndex == 0) return;
    _currentIndex--;
    _isEditing = false;
    _isNewRecord = false;
    loadCurrentRecord();
  }

  void goToNext() {
    if (_products.isEmpty || _currentIndex == _products.length - 1) return;
    _currentIndex++;
    _isEditing = false;
    _isNewRecord = false;
    loadCurrentRecord();
  }

  void goToLast() {
    if (_products.isEmpty) return;
    _currentIndex = _products.length - 1;
    _isEditing = false;
    _isNewRecord = false;
    loadCurrentRecord();
  }

  void addNew() {
    _isNewRecord = true;
    _isEditing = true;
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
    if (_products.isNotEmpty) {
      loadCurrentRecord();
    } else {
      notifyListeners();
    }
  }

  void setActive(bool value) {
    _isActive = value;
    notifyListeners();
  }

  void navigateToIndex(int index) {
    _currentIndex = index;
    _isEditing = false;
    _isNewRecord = false;
    loadCurrentRecord();
  }

  Future<OperationResult> saveRecord() async {
    if (_isSaving) return const OperationResult(false, 'Already saving');
    _isSaving = true;
    notifyListeners();

    try {
      final product = Product(
        id: _isNewRecord ? 0 : _products[_currentIndex].id,
        name: nameController.text.trim(),
        price: double.tryParse(priceController.text) ?? 0,
        description: descriptionController.text.trim(),
        stock: int.tryParse(stockController.text) ?? 0,
        isActive: _isActive,
        createdDate: _isNewRecord ? DateTime.now() : _products[_currentIndex].createdDate,
      );

      if (_isNewRecord) {
        await _apiService.createProduct(product);
      } else {
        await _apiService.updateProduct(product);
      }

      final wasNew = _isNewRecord;
      _isEditing = false;
      _isNewRecord = false;
      _isSaving = false;
      notifyListeners();
      await fetchProducts();
      return OperationResult(true, wasNew ? 'Product created successfully' : 'Product updated successfully');
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      return OperationResult(false, 'Error: $e');
    }
  }

  Future<OperationResult> deleteRecord() async {
    if (_products.isEmpty) return const OperationResult(false, 'No products to delete');

    try {
      await _apiService.deleteProduct(_products[_currentIndex].id);
      if (_currentIndex >= _products.length - 1 && _currentIndex > 0) {
        _currentIndex--;
      }
      await fetchProducts();
      return const OperationResult(true, 'Product deleted successfully');
    } catch (e) {
      return OperationResult(false, 'Error deleting product: $e');
    }
  }
}
