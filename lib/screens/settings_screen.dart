import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ApotekSettings _settings;
  bool _isSaving = false;

  final _namaCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _apotekerCtrl = TextEditingController();
  final _telponCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _settings = SettingsService.instance.loadSettings();
    _namaCtrl.text = _settings.namaApotek;
    _alamatCtrl.text = _settings.alamatApotek;
    _apotekerCtrl.text = _settings.namaApoteker;
    _telponCtrl.text = _settings.nomorTelepon;
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
    );
    if (picked == null) return;

    // Salin ke direktori app supaya path permanen
    final appDir = await getApplicationDocumentsDirectory();
    final dest = '${appDir.path}/logo_apotek.png';
    await File(picked.path).copy(dest);

    setState(() => _settings.logoPath = dest);
    _showSnack('Logo berhasil dipilih');
  }

  Future<void> _removeLogo() async {
    if (_settings.logoPath != null) {
      try {
        await File(_settings.logoPath!).delete();
      } catch (_) {}
    }
    setState(() => _settings.logoPath = null);
  }

  Future<void> _saveSettings() async {
    _settings.namaApotek = _namaCtrl.text.trim();
    _settings.alamatApotek = _alamatCtrl.text.trim();
    _settings.namaApoteker = _apotekerCtrl.text.trim();
    _settings.nomorTelepon = _telponCtrl.text.trim();

    setState(() => _isSaving = true);
    await SettingsService.instance.saveSettings(_settings);
    setState(() => _isSaving = false);
    _showSnack('Pengaturan disimpan!');
  }

  Future<void> _resetNomor() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Nomor Etiket'),
        content: const Text(
            'Nomor etiket akan direset ke 1.\nLanjutkan?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (confirm == true) {
      await SettingsService.instance.resetNomor();
      _showSnack('Nomor etiket direset ke 1');
    }
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
    _namaCtrl.dispose();
    _alamatCtrl.dispose();
    _apotekerCtrl.dispose();
    _telponCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Apotek')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Logo ─────────────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LOGO APOTEK',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[100],
                          ),
                          child: _settings.logoPath != null &&
                                  File(_settings.logoPath!).existsSync()
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_settings.logoPath!),
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : const Icon(Icons.store,
                                  size: 40, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickLogo,
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: const Text('Pilih Logo'),
                            ),
                            if (_settings.logoPath != null) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _removeLogo,
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                label: const Text('Hapus Logo',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Data Apotek ───────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DATA APOTEK',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _namaCtrl,
                      label: 'Nama Apotek',
                      hint: 'Contoh: APOTEK BIMA',
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 10),
                    _buildField(
                      controller: _alamatCtrl,
                      label: 'Alamat',
                      hint: 'Alamat lengkap apotek',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    _buildField(
                      controller: _apotekerCtrl,
                      label: 'Nama Apoteker',
                      hint: 'Contoh: apt. Nama, S.Farm.',
                    ),
                    const SizedBox(height: 10),
                    _buildField(
                      controller: _telponCtrl,
                      label: 'No. Telepon',
                      hint: '08xxx',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Menyimpan...' : 'SIMPAN PENGATURAN'),
                style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),

            // ── Reset Nomor ───────────────────────────────────────────────────
            Card(
              child: ListTile(
                leading: const Icon(Icons.restart_alt, color: Colors.orange),
                title: const Text('Reset Nomor Etiket'),
                subtitle: Text(
                    'Nomor saat ini: ${SettingsService.instance.loadNomorCounter()}'),
                trailing: TextButton(
                  onPressed: _resetNomor,
                  child: const Text('Reset', style: TextStyle(color: Colors.orange)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Versi ────────────────────────────────────────────────────────
            const Center(
              child: Text(
                'Etiket Apotek v1.0.0\nDibuat untuk Apotek Bima',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) =>
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
      );
}
