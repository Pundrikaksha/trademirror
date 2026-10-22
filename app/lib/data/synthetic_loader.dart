import 'package:flutter/services.dart' show rootBundle;

class SyntheticDataLoader {
  static const String sampleReadmePath = 'assets/sample/README.txt';

  Future<String> loadRawSampleText() async {
    return await rootBundle.loadString(sampleReadmePath);
  }
}
