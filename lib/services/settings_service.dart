import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._();
  SettingsService._();

  late SharedPreferences _prefs;

  static const _keySettings = 'apotek_settings';
  static const _keyEtiket = 'last_etiket';
  static const _keyPrinterMac = 'printer_mac';
  static const _keyPrinterName = 'printer_name';
  static const _keyNomorCounter = 'nomor_counter';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Apotek Settings ─────────────────────────────────────────────────────────
  ApotekSettings loadSettings() {
    final json = _prefs.getString(_keySettings);
    if (json == null) return ApotekSettings();
    try {
      return ApotekSettings.fromMap(jsonDecode(json));
    } catch (_) {
      return ApotekSettings();
    }
  }

  Future<void> saveSettings(ApotekSettings s) async {
    await _prefs.setString(_keySettings, jsonEncode(s.toMap()));
  }

  // ── Etiket Data ──────────────────────────────────────────────────────────────
  EtiketData loadEtiket() {
    final json = _prefs.getString(_keyEtiket);
    if (json == null) return EtiketData(nomorEtiket: loadNomorCounter());
    try {
      final data = EtiketData.fromMap(jsonDecode(json));
      // Selalu gunakan tanggal hari ini
      return data.copyWith(
        tanggal: _todayString(),
        nomorEtiket: loadNomorCounter(),
      );
    } catch (_) {
      return EtiketData(nomorEtiket: loadNomorCounter());
    }
  }

  String _todayString() {
    final now = DateTime.now();
    const bulan = [
      '', 'JANUARI', 'FEBRUARI', 'MARET', 'APRIL', 'MEI', 'JUNI',
      'JULI', 'AGUSTUS', 'SEPTEMBER', 'OKTOBER', 'NOVEMBER', 'DESEMBER'
    ];
    return '${now.day} ${bulan[now.month]} ${now.year}';
  }

  Future<void> saveEtiket(EtiketData e) async {
    await _prefs.setString(_keyEtiket, jsonEncode(e.toMap()));
  }

  // ── Nomor Counter ────────────────────────────────────────────────────────────
  int loadNomorCounter() => _prefs.getInt(_keyNomorCounter) ?? 1;

  Future<void> saveNomorCounter(int n) async {
    await _prefs.setInt(_keyNomorCounter, n);
  }

  Future<int> incrementNomor() async {
    final next = loadNomorCounter() + 1;
    await saveNomorCounter(next);
    return next;
  }

  Future<void> resetNomor() async {
    await saveNomorCounter(1);
  }

  // ── Printer ──────────────────────────────────────────────────────────────────
  PrinterDevice? loadDefaultPrinter() {
    final mac = _prefs.getString(_keyPrinterMac);
    final name = _prefs.getString(_keyPrinterName);
    if (mac == null || mac.isEmpty) return null;
    return PrinterDevice(name: name ?? mac, macAddress: mac);
  }

  Future<void> saveDefaultPrinter(PrinterDevice? printer) async {
    if (printer == null) {
      await _prefs.remove(_keyPrinterMac);
      await _prefs.remove(_keyPrinterName);
    } else {
      await _prefs.setString(_keyPrinterMac, printer.macAddress);
      await _prefs.setString(_keyPrinterName, printer.name);
    }
  }
}
