class ApotekSettings {
  String namaApotek;
  String alamatApotek;
  String namaApoteker;
  String nomorTelepon;
  String? logoPath; // path lokal file logo

  ApotekSettings({
    this.namaApotek = 'APOTEK BIMA',
    this.alamatApotek = 'JL. Bima, Nglaban, Sinduharjo, Ngaglik, Sleman',
    this.namaApoteker = 'apt. Puguh Indrasetiawan, S.Farm., M.Sc., Ph.D.',
    this.nomorTelepon = '082146129602',
    this.logoPath,
  });

  Map<String, dynamic> toMap() => {
        'namaApotek': namaApotek,
        'alamatApotek': alamatApotek,
        'namaApoteker': namaApoteker,
        'nomorTelepon': nomorTelepon,
        'logoPath': logoPath ?? '',
      };

  factory ApotekSettings.fromMap(Map<String, dynamic> map) => ApotekSettings(
        namaApotek: map['namaApotek'] ?? 'APOTEK BIMA',
        alamatApotek: map['alamatApotek'] ?? '',
        namaApoteker: map['namaApoteker'] ?? '',
        nomorTelepon: map['nomorTelepon'] ?? '',
        logoPath: (map['logoPath'] as String?)?.isNotEmpty == true
            ? map['logoPath']
            : null,
      );
}

class EtiketData {
  int nomorEtiket;
  String tanggal;
  String namaPasien;
  String baris1;
  String baris2;
  String baris3;
  String baris4;
  String baris5;

  EtiketData({
    this.nomorEtiket = 1,
    String? tanggal,
    this.namaPasien = '',
    this.baris1 = '',
    this.baris2 = '',
    this.baris3 = '',
    this.baris4 = '',
    this.baris5 = '',
  }) : tanggal = tanggal ?? _todayString();

  static String _todayString() {
    final now = DateTime.now();
    const bulan = [
      '', 'JANUARI', 'FEBRUARI', 'MARET', 'APRIL', 'MEI', 'JUNI',
      'JULI', 'AGUSTUS', 'SEPTEMBER', 'OKTOBER', 'NOVEMBER', 'DESEMBER'
    ];
    return '${now.day} ${bulan[now.month]} ${now.year}';
  }

  List<String> get barisAktif => [baris1, baris2, baris3, baris4, baris5]
      .where((b) => b.trim().isNotEmpty)
      .toList();

  Map<String, dynamic> toMap() => {
        'nomorEtiket': nomorEtiket,
        'tanggal': tanggal,
        'namaPasien': namaPasien,
        'baris1': baris1,
        'baris2': baris2,
        'baris3': baris3,
        'baris4': baris4,
        'baris5': baris5,
      };

  factory EtiketData.fromMap(Map<String, dynamic> map) => EtiketData(
        nomorEtiket: map['nomorEtiket'] ?? 1,
        tanggal: map['tanggal'],
        namaPasien: map['namaPasien'] ?? '',
        baris1: map['baris1'] ?? '',
        baris2: map['baris2'] ?? '',
        baris3: map['baris3'] ?? '',
        baris4: map['baris4'] ?? '',
        baris5: map['baris5'] ?? '',
      );

  EtiketData copyWith({
    int? nomorEtiket,
    String? tanggal,
    String? namaPasien,
    String? baris1,
    String? baris2,
    String? baris3,
    String? baris4,
    String? baris5,
  }) =>
      EtiketData(
        nomorEtiket: nomorEtiket ?? this.nomorEtiket,
        tanggal: tanggal ?? this.tanggal,
        namaPasien: namaPasien ?? this.namaPasien,
        baris1: baris1 ?? this.baris1,
        baris2: baris2 ?? this.baris2,
        baris3: baris3 ?? this.baris3,
        baris4: baris4 ?? this.baris4,
        baris5: baris5 ?? this.baris5,
      );
}

class PrinterDevice {
  final String name;
  final String macAddress;

  const PrinterDevice({required this.name, required this.macAddress});

  Map<String, dynamic> toMap() => {'name': name, 'macAddress': macAddress};

  factory PrinterDevice.fromMap(Map<String, dynamic> map) => PrinterDevice(
        name: map['name'] ?? '',
        macAddress: map['macAddress'] ?? '',
      );
}
