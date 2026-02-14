import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/metal_price_provider.dart';
import 'providers/news_provider.dart';
import 'providers/prediction_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for premium mobile experience
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MetalPriceProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => PredictionProvider()),
      ],
      child: const TheiaApp(),
    ),
  );
}
