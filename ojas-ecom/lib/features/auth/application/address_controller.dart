import 'package:flutter/material.dart';
import '../domain/models/address_model.dart';
import 'address_service.dart';

class AddressController extends ChangeNotifier {
  static final AddressController _instance = AddressController._internal();
  static AddressController get instance => _instance;

  AddressController._internal();

  final AddressService _addressService = AddressService();
  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  AddressModel? _selectedAddress;

  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  AddressModel? get selectedAddress => _selectedAddress;

  Future<void> loadAddresses() async {
    _isLoading = true;
    notifyListeners();

    _addresses = await _addressService.getAddresses();
    
    // Set default selected address if not already set or if current selected is not in the list
    if (_addresses.isNotEmpty) {
      final defaultAddr = _addresses.firstWhere((a) => a.isDefault, orElse: () => _addresses.first);
      _selectedAddress = defaultAddr;
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  Future<bool> addAddress(AddressModel address) async {
    _isLoading = true;
    notifyListeners();

    final success = await _addressService.addAddress(address);
    if (success) {
      await loadAddresses();
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateAddress(String id, AddressModel address) async {
    _isLoading = true;
    notifyListeners();

    final success = await _addressService.updateAddress(id, address);
    if (success) {
      await loadAddresses();
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteAddress(String id) async {
    _isLoading = true;
    notifyListeners();

    final success = await _addressService.deleteAddress(id);
    if (success) {
      await loadAddresses();
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> setDefaultAddress(String id) async {
    _isLoading = true;
    notifyListeners();

    final success = await _addressService.setDefaultAddress(id);
    if (success) {
      await loadAddresses();
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}
