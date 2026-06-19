import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/settings_service.dart';
import '../services/printer_service.dart';
import '../widgets/etiket_preview.dart';

class EtiketScreen extends StatefulWidget {
  const EtiketScreen({super.key});

  @override
  State<EtiketScreen> createState() => _EtiketScreenState();
}

class _EtiketScreenState extends State<EtiketScreen> {
  late EtiketData _etiket;
  late ApotekSettings _settings;
  bool _isPrinting = false;

  final _pasienCtrl = TextEditingController();
  final _baris1Ctrl = TextEditingController();
  final _baris2Ctrl = TextEditingController();
  final _baris3Ctrl = TextEditingController();
  final _baris4Ctrl = TextEditingController();
  final _baris5Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    PrinterService.instance.addListener(_onPrinterChange);
  }

  void _onPrinterChange() => setState(() {});

  void _loadData() {
    _settings = SettingsService.instance.loadSettings();
    _etiket = SettingsService.instance.loadEtiket();
    // Reset tanggal ke hari ini
    _etiket = _etiket.copyWith(tanggal: _todayString());
    _syncControllers();
  }

  String _todayString() {
    final now = DateTime.now();
    const bulan = [
      '', 'JANUARI', 'FEBRUARI', 'MARET', 'APRIL', 'MEI', 'JUNI',
      'JULI', 'AGUSTUS', 'SEPTEMBER', 'OKTOBER', 'NOVEMBER', 'DESEMBER'
    ];
    return '${now.day} ${bulan[now.month]} ${now.year}';
  }

  void _syncControllers() {
    _pasienCtrl.text = _etiket.namaPasien;
    _baris1Ctrl.text = _etiket.baris1;
    _baris2Ctrl.text = _etiket.baris2;
    _baris3Ctrl.text = _etiket.baris3;
    _baris4Ctrl.text = _etiket.baris4;
    _baris5Ctrl.text = _etiket.baris5;
  }

  void _updateEtiket() {
    _etiket = _etiket.copyWith(
      namaPasien: _pasienCtrl.text,
      baris1: _baris1Ctrl.text,
      baris2: _baris2Ctrl.text,
      baris3: _baris3Ctrl.text,
      baris4: _baris4Ctrl.text,
      baris5: _baris5Ctrl.text,
    );
    setState(() {});
    SettingsService.instance.saveEtiket(_etiket);
  }

  Future<void> _print() async {
    _updateEtiket();
    if (!PrinterService.instance.isConnected) {
      _showSnack('Printer belum terhubung. Buka menu Printer untuk memilih.', isError: true);
      return;
    }
    setState(() => _isPrinting = true);
    final ok = await PrinterService.instance.printEtiket(
      settings: _settings,
      etiket: _etiket,
    );
    if (ok) {
      // Increment nomor untuk etiket berikutnya
      final nextNo = await SettingsService.instance.incrementNomor();
      setState(() {
        _etiket = _etiket.copyWith(nomorEtiket: nextNo);
      });
      _showSnack('Etiket berhasil dicetak!');
    } else {
      _showSnack('Gagal mencetak. Cek koneksi printer.', isError: true);
    }
    setState(() => _isPrinting = false);
  }

  Future<void> _reprint() async {
    _updateEtiket();
    if (!PrinterService.instance.isConnected) {
      _showSnack('Printer belum terhubung.', isError: true);
      return;
    }
    setState(() => _isPrinting = true);
    // Reprint dengan nomor yang sama (tidak increment)
    final ok = await PrinterService.instance.printEtiket(
      settings: _settings,
      etiket: _etiket,
    );
    setState(() => _isPrinting = false);
    _showSnack(ok ? 'Reprint berhasil!' : 'Gagal reprint.', isError: !ok);
  }

  void _newEtiket() {
    setState(() {
      _pasienCtrl.clear();
      _baris1Ctrl.clear();
      _baris2Ctrl.clear();
      _baris3Ctrl.clear();
      _baris4Ctrl.clear();
      _baris5Ctrl.clear();
      _etiket = _etiket.copyWith(
        namaPasien: '',
        baris1: '',
        baris2: '',
        baris3: '',
        baris4: '',
        baris5: '',
      );
    });
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
    _pasienCtrl.dispose();
    _baris1Ctrl.dispose();
    _baris2Ctrl.dispose();
    _baris3Ctrl.dispose();
    _baris4Ctrl.dispose();
    _baris5Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final printerSvc = PrinterService.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cetak Etiket'),
        actions: [
          // Status printer indicator
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: Icon(
                Icons.bluetooth,
                size: 16,
                color: printerSvc.isConnected ? Colors.green : Colors.grey,
              ),
              label: Text(
                printerSvc.isConnected ? 'Terhubung' : 'Offline',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Preview Etiket ─────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PREVIEW ETIKET',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    const SizedBox(height: 8),
                    EtiketPreview(settings: _settings, etiket: _etiket),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Form Input ─────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // No & Tanggal (read-only info)
                    Row(children: [
                      Expanded(
                        child: _infoTile('No. Etiket',
                            _etiket.nomorEtiket.toString()),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _infoTile('Tanggal', _etiket.tanggal),
                      ),
                    ]),
                    const SizedBox(height: 10),

                    // Nama Pasien
                    _buildField(
                      controller: _pasienCtrl,
                      label: 'Nama Pasien',
                      hint: 'Masukkan nama pasien',
                      onChanged: (_) => _updateEtiket(),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 10),

                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('INSTRUKSI OBAT',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                    ),

                    _buildField(
                      controller: _baris1Ctrl,
                      label: 'Baris 1',
                      hint: 'Contoh: 3 X 1 TABLET',
                      onChanged: (_) => _updateEtiket(),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _baris2Ctrl,
                      label: 'Baris 2',
                      hint: 'Contoh: MALAM',
                      onChanged: (_) => _updateEtiket(),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _baris3Ctrl,
                      label: 'Baris 3',
                      hint: 'Contoh: SETELAH MAKAN',
                      onChanged: (_) => _updateEtiket(),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _baris4Ctrl,
                      label: 'Baris 4',
                      hint: 'Contoh: HABISKAN',
                      onChanged: (_) => _updateEtiket(),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _baris5Ctrl,
                      label: 'Baris 5',
                      hint: 'Contoh: SIMPAN DI TEMPAT KERING',
                      onChanged: (_) => _updateEtiket(),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Tombol Aksi ────────────────────────────────────────────────
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _newEtiket,
                  icon: const Icon(Icons.add),
                  label: const Text('Baru'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isPrinting ? null : _reprint,
                  icon: const Icon(Icons.replay),
                  label: const Text('Reprint'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isPrinting ? null : _print,
                icon: _isPrinting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.print),
                label: Text(_isPrinting ? 'Mencetak...' : 'CETAK ETIKET'),
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Function(String) onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) =>
      TextField(
        controller: controller,
        onChanged: onChanged,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    controller.clear();
                    _updateEtiket();
                  },
                )
              : null,
        ),
      );
}
