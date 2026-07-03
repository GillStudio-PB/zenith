// This file defines the ForexConverterScreen widget, which allows users to convert between different currencies and precious metals (gold and silver) based on live exchange rates. It uses Riverpod providers to fetch the latest forex rates and performs calculations to convert amounts between selected currencies. The screen provides a user-friendly interface with dropdowns for selecting currencies, input fields for entering amounts, and displays the converted result.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/forex_provider.dart';

class ForexConverterScreen extends ConsumerStatefulWidget {
  const ForexConverterScreen({super.key});

  @override
  ConsumerState<ForexConverterScreen> createState() =>
      _ForexConverterScreenState();
}

class _ForexConverterScreenState extends ConsumerState<ForexConverterScreen> {
  String _fromCurrency = 'AED';
  String _toCurrency = 'INR';
  final _amountController = TextEditingController(text: '1');
  double _result = 0.0;
  Map<String, double> _rates = {};

  void _calculate() {
    if (_rates.isEmpty) return;
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    // Convert to AED first, then to target currency
    // Our rates map is 'How many of this currency = 1 AED'
    // Wait, in my allRatesProvider, it's 1 AED = X USD (0.27), 1 AED = X INR (22.50).
    // BUT for gold/silver it is 'Price of 1g in AED'.
    // Wow, the provider rates have mixed representations!

    // Let's standardise how rates are used inside the converter based on how allRatesProvider provides them.
    // allRatesProvider provides:
    // 'AED' = 1.0 (1 AED = 1 AED)
    // 'INR' = 22.50 (1 AED = 22.50 INR) -> to get AED from INR: amount / 22.50
    // 'GOLD (1g)' = 285.50 (1g Gold = 285.50 AED) -> this is inverted! it should be how much gold = 1 AED.
    // Or we standardise here:

    double fromAedValue = 1.0;
    if (_fromCurrency.contains('GOLD') || _fromCurrency.contains('SILVER')) {
      // It's price in AED for 1 unit. So 1 unit = rate AED
      fromAedValue = amount * (_rates[_fromCurrency] ?? 1.0);
    } else {
      // It's how much of this currency = 1 AED
      fromAedValue = amount / (_rates[_fromCurrency] ?? 1.0);
    }

    double resultAmount = 0.0;
    if (_toCurrency.contains('GOLD') || _toCurrency.contains('SILVER')) {
      resultAmount = fromAedValue / (_rates[_toCurrency] ?? 1.0);
    } else {
      resultAmount = fromAedValue * (_rates[_toCurrency] ?? 1.0);
    }

    setState(() {
      _result = resultAmount;
    });
  }

  void _swap() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final ratesAsync = ref.watch(allRatesProvider);

    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Live FX & Metals',
              style:
                  TextStyle(fontWeight: FontWeight.w800, color: Colors.amber)),
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.amber),
          elevation: 0,
        ),
        body: ratesAsync.when(
          data: (rates) {
            if (_rates.isEmpty) {
              _rates = rates;
              WidgetsBinding.instance.addPostFrameCallback((_) => _calculate());
            }
            return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const Icon(Icons.currency_exchange,
                      size: 80, color: Colors.amber),
                  const SizedBox(height: 16),
                  Text('Global Exchange',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 18,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 48),
                  Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3))),
                      child: Column(children: [
                        _buildCurrencyInput('You Send', _fromCurrency, (v) {
                          setState(() => _fromCurrency = v!);
                          _calculate();
                        }, _amountController, rates.keys.toList()),
                        const SizedBox(height: 24),
                        Center(
                            child: InkWell(
                                onTap: _swap,
                                child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: Colors.black,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.amber
                                                .withValues(alpha: 0.5))),
                                    child: const Icon(Icons.swap_vert,
                                        color: Colors.amber)))),
                        const SizedBox(height: 24),
                        _buildCurrencyOutput('They Receive', _toCurrency, (v) {
                          setState(() => _toCurrency = v!);
                          _calculate();
                        }, _result, rates.keys.toList()),
                      ])),
                  const SizedBox(height: 48),
                  const Text('Market Rates are approximate.',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ]));
          },
          loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.amber)),
          error: (err, stack) => Center(
              child: Text('Error loading rates: $err',
                  style: const TextStyle(color: Colors.red))),
        ));
  }

  Widget _buildCurrencyInput(
      String label,
      String currency,
      ValueChanged<String?> onChanged,
      TextEditingController controller,
      List<String> availableCurrencies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: availableCurrencies.contains(currency)
                    ? currency
                    : availableCurrencies.first,
                dropdownColor: Colors.black,
                style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.black,
                ),
                items: availableCurrencies
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: onChanged,
              )),
          const SizedBox(width: 16),
          Expanded(
              flex: 3,
              child: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
                decoration: const InputDecoration(border: InputBorder.none),
                onChanged: (v) => _calculate(),
              ))
        ])
      ],
    );
  }

  Widget _buildCurrencyOutput(
      String label,
      String currency,
      ValueChanged<String?> onChanged,
      double result,
      List<String> availableCurrencies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: availableCurrencies.contains(currency)
                    ? currency
                    : availableCurrencies.first,
                dropdownColor: Colors.black,
                style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.black,
                ),
                items: availableCurrencies
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: onChanged,
              )),
          const SizedBox(width: 16),
          Expanded(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  result.toStringAsFixed(2),
                  style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 32,
                      fontWeight: FontWeight.w900),
                  textAlign: TextAlign.right,
                ),
              ))
        ])
      ],
    );
  }
}
