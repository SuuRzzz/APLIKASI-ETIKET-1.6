import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';

/// Preview visual etiket di layar (bukan ESC/POS)
/// Layout mengikuti desain screenshot: logo+header atas, no/tgl, pasien, OBAT, instruksi besar
class EtiketPreview extends StatelessWidget {
  final ApotekSettings settings;
  final EtiketData etiket;

  const EtiketPreview({
    super.key,
    required this.settings,
    required this.etiket,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: Logo + Nama/Alamat ────────────────────────────────────
          _buildHeader(),

          // ── No + Tanggal ──────────────────────────────────────────────────
          _divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Text('NO: ${etiket.nomorEtiket}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('TANGGAL: ${etiket.tanggal}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),

          // ── Pasien ────────────────────────────────────────────────────────
          _divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'PASIEN: ${etiket.namaPasien.toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),

          // ── OBAT label ────────────────────────────────────────────────────
          _divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Center(
              child: Text('OBAT:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),

          // ── Instruksi baris ───────────────────────────────────────────────
          _divider(),
          _buildInstruksi(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final hasLogo = settings.logoPath != null &&
        settings.logoPath!.isNotEmpty &&
        File(settings.logoPath!).existsSync();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo
          if (hasLogo)
            Container(
              width: 72,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey[400]!)),
              ),
              padding: const EdgeInsets.all(4),
              child: Image.file(
                File(settings.logoPath!),
                fit: BoxFit.contain,
              ),
            )
          else
            Container(
              width: 72,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey[400]!)),
                color: const Color(0xFF1A6B3A).withOpacity(0.1),
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.local_pharmacy,
                  size: 36, color: Color(0xFF1A6B3A)),
            ),

          // Info apotek
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    settings.namaApotek.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A6B3A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    settings.alamatApotek,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9),
                  ),
                  Text(
                    'Apoteker: ${settings.namaApoteker}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9),
                  ),
                  Text(
                    'No Telp: ${settings.nomorTelepon}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruksi() {
    final barisAktif = etiket.barisAktif;
    if (barisAktif.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: Text('(instruksi obat)',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
      );
    }

    return Column(
      children: barisAktif.asMap().entries.map((e) {
        final i = e.key;
        final baris = e.value.toUpperCase();
        // Baris 0 & 1 = besar & bold (sesuai screenshot)
        final isBig = i < 2;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: isBig ? 6 : 3,
            horizontal: 8,
          ),
          decoration: isBig
              ? BoxDecoration(
                  border: Border(
                    top: i == 0
                        ? BorderSide.none
                        : BorderSide(color: Colors.grey[300]!),
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                )
              : null,
          child: Center(
            child: Text(
              baris,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isBig ? 20 : 13,
                fontWeight: isBig ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _divider() =>
      Divider(height: 1, thickness: 1, color: Colors.grey[400]);
}
