import 'package:flutter/foundation.dart';
import '../models/metal_price.dart';
import '../models/prediction.dart';
import '../services/prediction_service.dart';
import '../utils/constants.dart';

class PredictionProvider extends ChangeNotifier {
  final PredictionService _service;

  PricePrediction? _goldPrediction;
  PricePrediction? _silverPrediction;
  bool _isLoading = false;
  String? _error;
  String _selectedMetal = AppConstants.gold;
  String _selectedWindow = AppConstants.predictionWindows.first;

  PredictionProvider({PredictionService? service})
      : _service = service ?? PredictionService();

  // Getters
  PricePrediction? get goldPrediction => _goldPrediction;
  PricePrediction? get silverPrediction => _silverPrediction;
  PricePrediction? get currentPrediction =>
      _selectedMetal == AppConstants.gold ? _goldPrediction : _silverPrediction;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedMetal => _selectedMetal;
  String get selectedWindow => _selectedWindow;

  /// Fetches predictions for both metals.
  Future<void> fetchPredictions({
    required double goldPrice,
    required double silverPrice,
    List<PricePoint>? goldHistory,
    List<PricePoint>? silverHistory,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getPrediction(
          metal: AppConstants.gold,
          window: _selectedWindow,
          currentPrice: goldPrice,
          historicalData: goldHistory,
        ),
        _service.getPrediction(
          metal: AppConstants.silver,
          window: _selectedWindow,
          currentPrice: silverPrice,
          historicalData: silverHistory,
        ),
      ]);

      _goldPrediction = results[0];
      _silverPrediction = results[1];
    } catch (e) {
      _error = 'Failed to generate predictions. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Changes the selected prediction window and refetches.
  void setWindow(String window, {double? goldPrice, double? silverPrice}) {
    if (_selectedWindow == window) return;
    _selectedWindow = window;
    notifyListeners();

    if (goldPrice != null && silverPrice != null) {
      fetchPredictions(goldPrice: goldPrice, silverPrice: silverPrice);
    }
  }

  /// Switches between gold and silver predictions.
  void setSelectedMetal(String metal) {
    if (_selectedMetal == metal) return;
    _selectedMetal = metal;
    notifyListeners();
  }
}
