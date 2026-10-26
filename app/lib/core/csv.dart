/// Minimal RFC 4180 CSV reader: quoted fields, doubled quotes ("") inside
/// quotes, commas and line breaks inside quotes, and CRLF / LF / CR endings.
library;

class CsvParseException implements Exception {
  CsvParseException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Returns one list of fields per record. Blank lines are skipped.
List<List<String>> parseCsv(String text) {
  if (text.startsWith('﻿')) text = text.substring(1);
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var fieldWasQuoted = false;
  var line = 1;
  var i = 0;

  void endField() {
    row.add(fieldWasQuoted ? field.toString() : field.toString().trim());
    field.clear();
    fieldWasQuoted = false;
  }

  void endRow() {
    endField();
    if (!(row.length == 1 && row.first.isEmpty)) rows.add(row);
    row = <String>[];
  }

  while (i < text.length) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        }
        inQuotes = false;
      } else {
        if (c == '\n') line++;
        field.write(c);
      }
      i++;
      continue;
    }
    if (c == '"') {
      if (field.toString().trim().isNotEmpty) {
        throw CsvParseException('Line $line: stray quote inside a field');
      }
      field.clear();
      inQuotes = true;
      fieldWasQuoted = true;
    } else if (c == ',') {
      endField();
    } else if (c == '\r' || c == '\n') {
      endRow();
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      line++;
    } else {
      if (fieldWasQuoted && c.trim().isNotEmpty) {
        throw CsvParseException('Line $line: text after a closing quote');
      }
      field.write(c);
    }
    i++;
  }
  if (inQuotes) {
    throw CsvParseException('Line $line: a quoted field is never closed');
  }
  if (field.isNotEmpty || row.isNotEmpty || fieldWasQuoted) endRow();
  return rows;
}
