// This file defines providers for fetching forex and gold rates using Riverpod. It includes providers for the current AED to INR exchange rate, the current 24k gold rate per gram in AED, and a provider that fetches all relevant rates from external APIs. The rates are fetched asynchronously and can be used throughout the application to display up-to-date financial information.
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// Fetches the current AED to INR exchange rate from an open API
final forexRateProvider = FutureProvider<double>((ref) async {
  final rates = await ref.watch(allRatesProvider.future);
  return rates['INR'] ?? 22.50;
});

// Fetches the current 24k Gold rate per gram in AED
final goldRateProvider = FutureProvider<double>((ref) async {
  final rates = await ref.watch(allRatesProvider.future);
  return rates['GOLD (1g)'] ?? 285.50;
});

final allRatesProvider = FutureProvider<Map<String, double>>((ref) async {
  final Map<String, double> rates = {
    'AED': 1.0,
    'USD': 0.27, // 1 AED in USD
    'INR': 22.50,
    'PKR': 75.0,
    'GBP': 0.21,
    'EUR': 0.25,
    'CAD': 0.36,
    'GOLD (1g)': 285.50,
    'SILVER (1g)': 3.50,
  };

  try {
    final response =
        await http.get(Uri.parse('https://open.er-api.com/v6/latest/AED'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final apiRates = data['rates'] as Map<String, dynamic>;
      rates['USD'] = (apiRates['USD'] as num).toDouble();
      rates['INR'] = (apiRates['INR'] as num).toDouble();
      rates['PKR'] = (apiRates['PKR'] as num).toDouble();
      rates['GBP'] = (apiRates['GBP'] as num).toDouble();
      rates['EUR'] = (apiRates['EUR'] as num).toDouble();
      rates['CAD'] = (apiRates['CAD'] as num).toDouble();
    }
  } catch (e) {
    // Ignore and use fallbacks
  }

  try {
    final response =
        await http.get(Uri.parse('https://api.metals.live/v1/spot/gold'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final usdPerOunce = data[0]['price'] as num?;
      if (usdPerOunce != null) {
        final usdPerGram = usdPerOunce.toDouble() / 31.1034768;
        rates['GOLD (1g)'] = usdPerGram * 3.6725;
      }
    }
  } catch (e) {}

  try {
    final response =
        await http.get(Uri.parse('https://api.metals.live/v1/spot/silver'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final usdPerOunce = data[0]['price'] as num?;
      if (usdPerOunce != null) {
        final usdPerGram = usdPerOunce.toDouble() / 31.1034768;
        rates['SILVER (1g)'] = usdPerGram * 3.6725;
      }
    }
  } catch (e) {}

  return rates;
});
