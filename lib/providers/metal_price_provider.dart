// ignore_for_file: unnecessary_overrides

import 'package:flutter/foundation.dart';
import '../models/metal_price.dart';
import '../services/metal_price_service.dart';
import '../utils/constants.dart';

class MetalPriceProvider extends ChangeNotifier {
  final MetalPriceService _service;

  List<MetalPrice> _prices = [];
  MetalPriceHistory? _goldHistory;
  MetalPriceHistory? _silverHistory;
  bool _isLoading = false;
  bool _isHistoryLoading = false;
  String? _error;
  String _selectedTimeRange = '7D';
  String _selectedMetal = AppConstants.gold;
  DateTime? _lastUpdated;

  MetalPriceProvider({MetalPriceService? service})
      : _service = service ?? MetalPriceService();

  // Getters
  List<MetalPrice> get prices => _prices;
  List<MetalPrice> get goldPrices =>
      _prices.where((p) => p.metal == AppConstants.gold).toList();
  List<MetalPrice> get silverPrices =>
      _prices.where((p) => p.metal == AppConstants.silver).toList();
  MetalPriceHistory? get goldHistory => _goldHistory;
  MetalPriceHistory? get silverHistory => _silverHistory;
  MetalPriceHistory? get currentHistory =>
      _selectedMetal == AppConstants.gold ? _goldHistory : _silverHistory;
  bool get isLoading => _isLoading;
  bool get isHistoryLoading => _isHistoryLoading;
  String? get error => _error;
  String get selectedTimeRange => _selectedTimeRange;
  String get selectedMetal => _selectedMetal;
  DateTime? get lastUpdated => _lastUpdated;

  MetalPrice? get gold24k => _prices.cast<MetalPrice?>().firstWhere(
        (p) => p!.metal == AppConstants.gold && p.karat == AppConstants.gold24k,
        orElse: () => null,
      );

  MetalPrice? get gold22k => _prices.cast<MetalPrice?>().firstWhere(
        (p) => p!.metal == AppConstants.gold && p.karat == AppConstants.gold22k,
        orElse: () => null,
      );

  MetalPrice? get silverPerGram => _prices.cast<MetalPrice?>().firstWhere(
        (p) => p!.metal == AppConstants.silver && p.unit == 'g',
        orElse: () => null,
      );

  MetalPrice? get silverPerKg => _prices.cast<MetalPrice?>().firstWhere(
        (p) => p!.metal == AppConstants.silver && p.unit == 'kg',
        orElse: () => null,
      );

  /// Initialize the provider: load cached data and fetch fresh data.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Try loading cached data first for instant display
    final cached = await _service.getCachedPrices();
    if (cached != null && cached.isNotEmpty) {
      _prices = cached;
      _lastUpdated = cached.first.lastUpdated;
      notifyListeners();
    }

    // Fetch fresh data once on app launch
    await fetchPrices();
    await fetchHistory();
  }

  /// Fetches the latest live prices.
  Future<void> fetchPrices() async {
    _isLoading = _prices.isEmpty;
    _error = null;
    notifyListeners();

    try {
      _prices = await _service.fetchLivePrices();
      _lastUpdated = DateTime.now();
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch prices. Showing last known data.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetches historical price data for both metals.
  Future<void> fetchHistory() async {
    _isHistoryLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.fetchHistory(AppConstants.gold, _selectedTimeRange),
        _service.fetchHistory(AppConstants.silver, _selectedTimeRange),
      ]);
      _goldHistory = results[0];
      _silverHistory = results[1];
    } catch (e) {
      // Keep existing history data
    }

    _isHistoryLoading = false;
    notifyListeners();
  }

  /// Changes the selected time range and refetches history.
  void setTimeRange(String timeRange) {
    if (_selectedTimeRange == timeRange) return;
    _selectedTimeRange = timeRange;
    notifyListeners();
    fetchHistory();
  }

  /// Switches between Gold and Silver view.
  void setSelectedMetal(String metal) {
    if (_selectedMetal == metal) return;
    _selectedMetal = metal;
    notifyListeners();
  }

  /// Pull-to-refresh handler.
  Future<void> refresh() async {
    await Future.wait([
      fetchPrices(),
      fetchHistory(),
    ]);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
