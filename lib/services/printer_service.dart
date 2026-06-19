import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_lts/esc_pos_utils_lts.dart';
import 'package:image/image.dart' as img;
import '../models/models.dart';
import 'settings_service.dart';

enum PrinterStatus { disconnected, connecting, connected, error }

class PrinterService extends ChangeNotifier {
  static final PrinterService instance = PrinterService._();
  PrinterService._();

  PrinterStatus _status = PrinterStatus.disconnected;
  PrinterDevice? _connectedPrinter;
  String _statusMessage = 'Tidak terhubung';

  PrinterStatus get status => _status;
  PrinterDevice? get connectedPrinter => _connectedPrinter;
  String get statusMessage => _statusMessage;
  bool get isConnected => _status == PrinterStatus.connected;

  // ── Paired devices ───────────────────────────────────────────────────────────
  Future<List<PrinterDevice>> getPairedDevices() async {
    try {
      final List<BluetoothInfo> paired =
          await PrintBluetoothThermal.pairedBluetooths;
      return paired
          .map((b) => PrinterDevice(name: b.name, macAddress: b.macAdress))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ── Connect ──────────────────────────────────────────────────────────────────
  Future<bool> connect(PrinterDevice printer) async {
    _setStatus(PrinterStatus.connecting, 'Menghubungkan ke ${printer.name}...');
    try {
      final result = await PrintBluetoothThermal.connect(
        macPrinterAddress: printer.macAddress,
      ).timeout(const Duration(seconds: 8));
      if (result) {
        _connectedPrinter = printer;
        _setStatus(PrinterStatus.connected, 'Terhubung: ${printer.name}');
        await SettingsService.instance.saveDefaultPrinter(printer);
        return true;
      } else {
        _setStatus(PrinterStatus.error, 'Gagal menghubungkan ke ${printer.name}');
        return false;
      }
    } catch (e) {
      _setStatus(PrinterStatus.error, 'Timeout koneksi ke ${printer.name}');
      return false;
    }
  }

  // ── Disconnect ───────────────────────────────────────────────────────────────
  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (_) {}
    _connectedPrinter = null;
    _setStatus(PrinterStatus.disconnected, 'Tidak terhubung');
  }

  // ── Auto-reconnect ke printer default ───────────────────────────────────────
  Future<bool> autoConnect() async {
    final defaultPrinter = SettingsService.instance.loadDefaultPrinter();
    if (defaultPrinter == null) return false;
    return connect(defaultPrinter);
  }

  // ── Cek koneksi aktif ────────────────────────────────────────────────────────
  Future<bool> checkConnection() async {
    try {
      final connected = await PrintBluetoothThermal.connectionStatus;
      if (!connected && _status == PrinterStatus.connected) {
        _connectedPrinter = null;
        _setStatus(PrinterStatus.disconnected, 'Koneksi terputus');
      } else if (connected && _status != PrinterStatus.connected) {
        _setStatus(PrinterStatus.connected,
            'Terhubung: ${_connectedPrinter?.name ?? ""}');
      }
      return connected;
    } catch (_) {
      return false;
    }
  }

  // ── Test print ───────────────────────────────────────────────────────────────
  Future<bool> testPrint() async {
    if (!isConnected) return false;
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];
      bytes += generator.reset();
      bytes += generator.text('TEST PRINT',
          styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2));
      bytes += generator.text('Etiket Apotek', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Printer OK', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(2);
      bytes += generator.cut();
      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      debugPrint('Test print error: $e');
      return false;
    }
  }

  // ── Cetak Etiket ─────────────────────────────────────────────────────────────
  Future<bool> printEtiket({
    required ApotekSettings settings,
    required EtiketData etiket,
  }) async {
    // Auto-reconnect jika putus
    if (!isConnected) {
      final reconnected = await autoConnect();
      if (!reconnected) {
        _setStatus(PrinterStatus.error, 'Printer tidak terhubung');
        return false;
      }
    }

    // Cek lagi status aktual
    final connected = await checkConnection();
    if (!connected) {
      _setStatus(PrinterStatus.error, 'Printer tidak merespons');
      return false;
    }

    try {
      final bytes = await _buildEtiketBytes(settings, etiket);
      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      debugPrint('Print error: $e');
      _setStatus(PrinterStatus.error, 'Gagal cetak: $e');
      return false;
    }
  }

  // ── Builder ESC/POS untuk etiket 4x7cm (≈ 58mm roll) ───────────────────────
  // 58mm printer: ~32 karakter per baris pada ukuran normal
  Future<List<int>> _buildEtiketBytes(
      ApotekSettings settings, EtiketData etiket) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.reset();

    // ── LOGO + HEADER APOTEK ────────────────────────────────────────────────
    // Coba cetak logo jika tersedia
    if (settings.logoPath != null && settings.logoPath!.isNotEmpty) {
      try {
        final logoFile = File(settings.logoPath!);
        if (await logoFile.exists()) {
          final rawBytes = await logoFile.readAsBytes();
          final decoded = img.decodeImage(rawBytes);
          if (decoded != null) {
            // Resize ke lebar maksimal 120px untuk 58mm
            final resized = img.copyResize(decoded, width: 120);
            bytes += generator.image(resized,
                align: PosAlign.left);
          }
        }
      } catch (e) {
        debugPrint('Logo error: $e');
      }
    }

    // Nama apotek - BESAR
    bytes += generator.text(
      settings.namaApotek.toUpperCase(),
      styles: const PosStyles(
        bold: true,
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
      ),
    );

    // Alamat - wrap jika perlu
    final alamatLines = _wrapText(settings.alamatApotek, 32);
    for (final line in alamatLines) {
      bytes += generator.text(line,
          styles: const PosStyles(align: PosAlign.center));
    }

    // Apoteker
    final apotLines = _wrapText('Apoteker: ${settings.namaApoteker}', 32);
    for (final line in apotLines) {
      bytes += generator.text(line,
          styles: const PosStyles(align: PosAlign.center));
    }

    // Telepon
    bytes += generator.text('No Telp: ${settings.nomorTelepon}',
        styles: const PosStyles(align: PosAlign.center));

    bytes += generator.hr();

    // ── NO & TANGGAL ────────────────────────────────────────────────────────
    bytes += generator.row([
      PosColumn(
        text: 'NO: ${etiket.nomorEtiket}',
        width: 4,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: 'TGL: ${etiket.tanggal}',
        width: 8,
        styles: const PosStyles(bold: true),
      ),
    ]);

    bytes += generator.hr();

    // ── PASIEN ───────────────────────────────────────────────────────────────
    bytes += generator.text('PASIEN: ${etiket.namaPasien.toUpperCase()}',
        styles: const PosStyles(bold: true));

    bytes += generator.hr();

    // ── OBAT header ──────────────────────────────────────────────────────────
    bytes += generator.text('OBAT:',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ));

    bytes += generator.emptyLines(1);

    // ── BARIS INSTRUKSI (ukuran besar, rata tengah) ──────────────────────────
    final barisAktif = etiket.barisAktif;
    for (int i = 0; i < barisAktif.length; i++) {
      final baris = barisAktif[i].toUpperCase();
      // Baris pertama dan kedua = BESAR, sisanya normal
      if (i < 2) {
        bytes += generator.text(
          baris,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        );
      } else {
        bytes += generator.text(
          baris,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: false,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          ),
        );
      }
      bytes += generator.emptyLines(1);
    }

    bytes += generator.hr();
    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }

  // ── Helper: wrap teks ke lebar tertentu ──────────────────────────────────────
  List<String> _wrapText(String text, int maxWidth) {
    if (text.length <= maxWidth) return [text];
    final words = text.split(' ');
    final lines = <String>[];
    var current = '';
    for (final word in words) {
      if (current.isEmpty) {
        current = word;
      } else if ((current + ' ' + word).length <= maxWidth) {
        current += ' $word';
      } else {
        lines.add(current);
        current = word;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  void _setStatus(PrinterStatus status, String message) {
    _status = status;
    _statusMessage = message;
    notifyListeners();
  }
}
