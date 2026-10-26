import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/mirror.dart';
import '../core/tradebook.dart';

const sampleAssetPathFile = 'sample_tradebook_kotak_neo_SYNTHETIC.csv';
const sampleAssetPath = 'assets/sample/$sampleAssetPathFile';

/// Holds the currently imported tradebook. Everything stays in memory on the
/// device; nothing is saved or sent anywhere.
class MirrorStore extends ChangeNotifier {
  MirrorResult? result;
  String? sourceName;
  bool isSample = false;
  String? error;
  bool loading = false;

  /// Parses [csvText] and replaces the current result. Returns true on success.
  bool importText(String csvText, {required String name, bool sample = false}) {
    try {
      final fills = parseKotakNeoTradebook(csvText);
      result = analyse(fills);
      sourceName = name;
      isSample = sample;
      error = null;
      notifyListeners();
      return true;
    } on TradebookException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loadSample() async {
    final text = await rootBundle.loadString(sampleAssetPath);
    return importText(text, name: sampleAssetPathFile, sample: true);
  }

  void setLoading(bool v) {
    loading = v;
    notifyListeners();
  }

  void showError(String message) {
    error = message;
    notifyListeners();
  }

  void clear() {
    result = null;
    sourceName = null;
    isSample = false;
    error = null;
    notifyListeners();
  }
}

final mirrorStore = MirrorStore();
