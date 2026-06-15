import 'package:flutter/material.dart';

class GlobalSearchService {
  final ValueNotifier<String> searchQuery = ValueNotifier<String>('');

  void updateSearch(String query) {
    searchQuery.value = query;
  }

  void clearSearch() {
    searchQuery.value = '';
  }
}
