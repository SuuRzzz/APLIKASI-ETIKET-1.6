import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/models.dart';
import '../services/printer_service.dart';
import '../services/settings_service.dart';

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  List<PrinterDevice> _pairedDevices = [];
  bool _isLoading = false;
  bool _isTesting = false;
  PrinterDevice? _defaultPrinter;

  @override
  void initState() {
    super.initState();
    _defaultPrinter = SettingsService.instance.loadDefaultPrinter();
    PrinterService.instance.addListener(_onPrinterChange);
    _loadPairedDevices();
  }

  void _onPrinterChange() => setState(() {
        _defaultPrinter = SettingsService.instance.loadDefaultPrinter();
      });

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
  }

  Future<void> _loadPairedDevices() async {
    await _requestPermissions();
    setState(() => _isLoading = true);
    final devices = await PrinterService.instance.getPairedDevices();
    setState(() {
      _pairedDevices = devices;
      _isLoading = false;
    });
  }

  Future<void> _connectTo(PrinterDevice device) async {
    setState(() => _isLoading = true);
    final ok = await PrinterService.instance.connect(device);
    setState(() => _isLoading = false);
    if (ok) {
      setState(() => _defaultPrinter = device);
      _showSnack('Berhasil terhubung ke ${device.name}');
    } else {
      _showSnack('Gagal terhubung ke ${device.name}', isError: true);
    }
  }

  Future<void> _disconnect() async {
    await PrinterService.instance.disconnect();
    setState(() {});
    _showSnack('Printer diputus');
  }

  Future<void> _testPrint() async {
    setState(() => _isTesting = true);
    final ok = await PrinterService.instance.testPrint();
    setState(() => _isTesting = false);
    _showSnack(ok ? 'Test print berhasil!' : 'Test print gagal', isError: !ok);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  void dispose() {
    PrinterService.instance.removeListener(_onPrinterChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final printerSvc = PrinterService.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Printer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh daftar printer',
            onPressed: _loadPairedDevices,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Status kartu ────────────────────────────────────────────────
            Card(
              color: printerSvc.isConnected
                  ? Colors.green[50]
                  : Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          printerSvc.isConnected
                              ? Icons.bluetooth_connected
                              : Icons.bluetooth_disabled,
                          color: printerSvc.isConnected
                              ? Colors.green
                              : Colors.orange,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                printerSvc.isConnected
                                    ? 'Terhubung'
                                    : 'Tidak Terhubung',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: printerSvc.isConnected
                                      ? Colors.green[800]
                                      : Colors.orange[800],
                                ),
                              ),
                              Text(
                                printerSvc.connectedPrinter?.name ??
                                    printerSvc.statusMessage,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (printerSvc.isConnected) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isTesting ? null : _testPrint,
                            icon: _isTesting
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.print),
                            label: const Text('Test Print'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green[700]),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _disconnect,
                          icon: const Icon(Icons.bluetooth_disabled),
                          label: const Text('Putuskan'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Printer Default ──────────────────────────────────────────────
            if (_defaultPrinter != null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: Text(_defaultPrinter!.name),
                  subtitle: Text(_defaultPrinter!.macAddress),
                  trailing: !printerSvc.isConnected
                      ? TextButton(
                          onPressed: () => _connectTo(_defaultPrinter!),
                          child: const Text('Hubungkan'),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Daftar Paired Devices ────────────────────────────────────────
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'PERANGKAT BLUETOOTH TERSIMPAN',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_pairedDevices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.bluetooth_searching,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Tidak ada perangkat tersimpan.\nPasangkan printer lewat\nPengaturan Bluetooth Android.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ...(_pairedDevices.map((device) {
                      final isConnected =
                          printerSvc.connectedPrinter?.macAddress ==
                              device.macAddress;
                      return ListTile(
                        leading: Icon(
                          Icons.print,
                          color: isConnected ? Colors.green : Colors.grey,
                        ),
                        title: Text(device.name),
                        subtitle: Text(device.macAddress,
                            style: const TextStyle(fontSize: 12)),
                        trailing: isConnected
                            ? const Chip(
                                label: Text('Terhubung',
                                    style: TextStyle(fontSize: 11)),
                                backgroundColor: Colors.green,
                                labelStyle: TextStyle(color: Colors.white),
                                padding: EdgeInsets.zero,
                              )
                            : TextButton(
                                onPressed: () => _connectTo(device),
                                child: const Text('Pilih'),
                              ),
                      );
                    })),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Panduan ──────────────────────────────────────────────────────
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CARA MENGHUBUNGKAN PRINTER',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey)),
                    SizedBox(height: 8),
                    Text(
                        '1. Nyalakan printer thermal Bluetooth\n'
                        '2. Buka Pengaturan → Bluetooth di HP\n'
                        '3. Pasangkan (pair) printer\n'
                        '4. Kembali ke aplikasi ini\n'
                        '5. Tekan Refresh → pilih printer\n'
                        '6. Tekan "Test Print" untuk verifikasi',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
