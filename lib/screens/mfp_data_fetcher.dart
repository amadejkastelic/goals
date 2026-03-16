import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/mfp_nutrition.dart';

class MFPDataFetcher extends StatefulWidget {
  final DateTime date;

  const MFPDataFetcher({super.key, required this.date});

  @override
  State<MFPDataFetcher> createState() => _MFPDataFetcherState();
}

class _MFPDataFetcherState extends State<MFPDataFetcher> {
  static const _loggedInKey = 'mfp_logged_in';

  late final WebViewController _controller;
  bool _isLoading = true;
  String? _status;
  MFPNutrition? _extractedData;
  bool _isLoggedIn = false;
  bool _showWebView = true;

  @override
  void initState() {
    super.initState();
    _status = 'Loading MyFitnessPal...';
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_loggedInKey) ?? false;

    setState(() => _showWebView = !_isLoggedIn);

    final dateStr =
        '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _status = 'Loading...';
            });
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _handlePageLoad(url);
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://www.myfitnesspal.com/food/diary?date=$dateStr'),
      );
  }

  Future<void> _handlePageLoad(String url) async {
    if (url.contains('/account/login')) {
      setState(() {
        _status = 'Please log in to MyFitnessPal';
        _showWebView = true;
      });
      return;
    }

    if (url.contains('/food/diary') || url.contains('/dashboard')) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _tryExtractData();
    }
  }

  Future<void> _markLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
    _isLoggedIn = true;
  }

  Future<void> _tryExtractData() async {
    setState(() => _status = 'Extracting nutrition data...');

    try {
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          var result = {calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sodium: 0, sugar: 0, debug: ''};
          
          function parseNum(s) {
            if (!s) return 0;
            s = s.trim().replace(/,/g, '').split(/[^0-9.]/)[0];
            return parseFloat(s) || 0;
          }
          
          var table = document.getElementById('diary-table') || document.querySelector('table.diary-table') || document.querySelector('table');
          if (!table) {
            result.debug = 'No table found';
            return JSON.stringify(result);
          }
          
          var rows = table.querySelectorAll('tr');
          result.debug = 'Found ' + rows.length + ' rows';
          
          var headers = [];
          var headerRow = table.querySelector('thead tr') || rows[0];
          if (headerRow) {
            headerRow.querySelectorAll('th, td').forEach(function(cell) {
              headers.push(cell.textContent.trim().toLowerCase());
            });
          }
          result.debug += ', headers: ' + headers.join('|');
          
          var calIdx = headers.findIndex(function(h) { return h.includes('calories'); });
          var carbIdx = headers.findIndex(function(h) { return h.includes('carbs') || h.includes('carb'); });
          var fatIdx = headers.findIndex(function(h) { return h.includes('fat'); });
          var protIdx = headers.findIndex(function(h) { return h.includes('protein') || h.includes('prot'); });
          var fiberIdx = headers.findIndex(function(h) { return h.includes('fiber'); });
          var sodiumIdx = headers.findIndex(function(h) { return h.includes('sodium'); });
          var sugarIdx = headers.findIndex(function(h) { return h.includes('sugar'); });
          
          result.debug += ', idx: c' + calIdx + ' cb' + carbIdx + ' f' + fatIdx + ' p' + protIdx;
          
          for (var i = rows.length - 1; i >= 0; i--) {
            var row = rows[i];
            var cells = row.querySelectorAll('td');
            var text = row.textContent.toLowerCase();
            
            if (text.includes('total') && !text.includes('daily')) {
              if (calIdx >= 0 && calIdx < cells.length) result.calories = parseNum(cells[calIdx].textContent);
              if (carbIdx >= 0 && carbIdx < cells.length) result.carbs = parseNum(cells[carbIdx].textContent);
              if (fatIdx >= 0 && fatIdx < cells.length) result.fat = parseNum(cells[fatIdx].textContent);
              if (protIdx >= 0 && protIdx < cells.length) result.protein = parseNum(cells[protIdx].textContent);
              break;
            }
          }
          
          for (var i = 0; i < rows.length; i++) {
            var row = rows[i];
            var cells = row.querySelectorAll('td');
            var text = row.textContent.toLowerCase();
            
            if (text.includes('fiber') && fiberIdx >= 0 && fiberIdx < cells.length) {
              result.fiber = parseNum(cells[fiberIdx].textContent);
            }
            if (text.includes('sodium') && sodiumIdx >= 0 && sodiumIdx < cells.length) {
              result.sodium = parseNum(cells[sodiumIdx].textContent);
            }
            if (text.includes('sugar') && sugarIdx >= 0 && sugarIdx < cells.length) {
              result.sugar = parseNum(cells[sugarIdx].textContent);
            }
          }
          
          return JSON.stringify(result);
        })();
      ''');

      final jsonStr = result.toString();
      debugPrint('MFP extraction result: $jsonStr');

      String cleanJson = jsonStr;
      if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
        cleanJson = jsonDecode(jsonStr) as String;
      }

      final decoded = jsonDecode(cleanJson) as Map<String, dynamic>;
      debugPrint('MFP debug: ${decoded['debug']}');

      final nutrition = MFPNutrition(
        calories: (decoded['calories'] as num?)?.toInt() ?? 0,
        protein: (decoded['protein'] as num?)?.toDouble() ?? 0,
        carbs: (decoded['carbs'] as num?)?.toDouble() ?? 0,
        fat: (decoded['fat'] as num?)?.toDouble() ?? 0,
        fiber: (decoded['fiber'] as num?)?.toDouble(),
        sodium: (decoded['sodium'] as num?)?.toDouble(),
        sugar: (decoded['sugar'] as num?)?.toDouble(),
      );

      setState(() {
        _extractedData = nutrition;
        _status = nutrition.calories > 0
            ? 'Found: ${nutrition.calories} cal, ${nutrition.protein.toStringAsFixed(0)}g protein'
            : 'No data found. Tap "Retry" or check if you have entries for this date.';
      });

      if (nutrition.calories > 0) {
        await _markLoggedIn();
        setState(() => _showWebView = false);
      }
    } catch (e) {
      debugPrint('MFP extraction error: $e');
      setState(() => _status = 'Error extracting data: $e');
    }
  }

  void _confirmImport() {
    if (_extractedData != null && _extractedData!.calories > 0) {
      Navigator.of(context).pop(_extractedData);
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    _isLoggedIn = false;
    _extractedData = null;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _status = 'Loading...';
            });
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _handlePageLoad(url);
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.myfitnesspal.com/account/logout'));

    setState(() {
      _showWebView = true;
      _status = 'Logged out. Reloading...';
    });

    await Future.delayed(const Duration(seconds: 1));

    final dateStr =
        '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';
    _controller.loadRequest(
      Uri.parse('https://www.myfitnesspal.com/food/diary?date=$dateStr'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyFitnessPal'),
        actions: [
          TextButton(onPressed: _clearSession, child: const Text('Logout')),
          TextButton(
            onPressed: _isLoading ? null : _tryExtractData,
            child: const Text('Retry'),
          ),
          if (_extractedData != null && _extractedData!.calories > 0)
            TextButton(onPressed: _confirmImport, child: const Text('Import')),
        ],
      ),
      body: Stack(
        children: [
          Visibility(
            visible: _showWebView,
            maintainState: true,
            child: WebViewWidget(controller: _controller),
          ),
          if (!_showWebView)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else ...[
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _status ?? 'Data loaded',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (_extractedData != null &&
                        _extractedData!.calories > 0) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        children: [
                          Text('🔥 ${_extractedData!.calories} cal'),
                          Text(
                            '🥩 ${_extractedData!.protein.toStringAsFixed(0)}g',
                          ),
                          Text(
                            '🍞 ${_extractedData!.carbs.toStringAsFixed(0)}g',
                          ),
                          Text('🧈 ${_extractedData!.fat.toStringAsFixed(0)}g'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _clearSession,
                      icon: const Icon(Icons.login),
                      label: const Text('Re-login'),
                    ),
                  ],
                ],
              ),
            ),
          if (_showWebView)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (_isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (_extractedData != null &&
                            _extractedData!.calories > 0)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _status ?? '',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    if (_extractedData != null &&
                        _extractedData!.calories > 0) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        children: [
                          Text('🔥 ${_extractedData!.calories} cal'),
                          Text(
                            '🥩 ${_extractedData!.protein.toStringAsFixed(0)}g',
                          ),
                          Text(
                            '🍞 ${_extractedData!.carbs.toStringAsFixed(0)}g',
                          ),
                          Text('🧈 ${_extractedData!.fat.toStringAsFixed(0)}g'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
