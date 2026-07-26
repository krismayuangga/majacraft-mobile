/// Daftar lengkap 102+ bank di Indonesia
/// Data ini digunakan untuk dropdown searchable di form rekening bank
class BankData {
  final String code;
  final String name;

  const BankData({required this.code, required this.name});
}

/// List lengkap bank Indonesia (102+ bank)
/// Source: Bank Indonesia, OJK, dan berbagai sumber official
const List<BankData> INDONESIA_BANKS = [
  // Bank BUMN
  BankData(code: '002', name: 'Bank BRI'),
  BankData(code: '008', name: 'Bank Mandiri'),
  BankData(code: '009', name: 'Bank BNI'),
  BankData(code: '427', name: 'Bank BNI Syariah'),
  BankData(code: '200', name: 'Bank BTN'),
  BankData(code: '451', name: 'Bank Syariah Indonesia (BSI)'),

  // Bank Swasta Nasional - Buku 4
  BankData(code: '014', name: 'Bank BCA'),
  BankData(code: '536', name: 'Bank BCA Syariah'),
  BankData(code: '022', name: 'Bank CIMB Niaga'),
  BankData(code: '022', name: 'Bank CIMB Niaga Syariah'),
  BankData(code: '011', name: 'Bank Danamon'),
  BankData(code: '013', name: 'Bank Permata'),
  BankData(code: '213', name: 'Bank Permata Syariah'),
  BankData(code: '016', name: 'Bank Maybank Indonesia'),
  BankData(code: '019', name: 'Bank Panin'),
  BankData(code: '517', name: 'Bank Panin Dubai Syariah'),
  BankData(code: '028', name: 'Bank OCBC NISP'),
  BankData(code: '023', name: 'Bank UOB Indonesia'),

  // Bank Swasta Nasional - Buku 3
  BankData(code: '037', name: 'Bank Artha Graha Internasional'),
  BankData(code: '542', name: 'Bank Jago'),
  BankData(code: '041', name: 'Bank Hana'),
  BankData(code: '046', name: 'Bank DBS Indonesia'),
  BankData(code: '050', name: 'Bank Ina Perdana'),
  BankData(code: '054', name: 'Bank Capital Indonesia'),
  BankData(code: '061', name: 'Bank ANZ Indonesia'),
  BankData(code: '067', name: 'Bank Commonwealth'),
  BankData(code: '069', name: 'Bank Oke Indonesia (Bank Andara)'),
  BankData(code: '087', name: 'Bank Ekonomi Raharja'),
  BankData(code: '089', name: 'Bank Haga'),
  BankData(code: '093', name: 'Bank IFI'),
  BankData(code: '097', name: 'Bank Mayapada'),
  BankData(code: '110', name: 'Bank Jabar Banten (BJB)'),
  BankData(code: '425', name: 'Bank Jabar Banten Syariah'),
  BankData(code: '111', name: 'Bank DKI'),
  BankData(code: '112', name: 'Bank Jatim'),
  BankData(code: '113', name: 'Bank DIY'),
  BankData(code: '114', name: 'Bank Jateng'),
  BankData(code: '115', name: 'Bank Kalsel'),
  BankData(code: '116', name: 'Bank Kalbar'),
  BankData(code: '117', name: 'Bank Kaltimtara'),
  BankData(code: '118', name: 'Bank Kalteng'),
  BankData(code: '119', name: 'Bank Sulselbar'),
  BankData(code: '120', name: 'Bank Sulut'),
  BankData(code: '121', name: 'Bank NTB'),
  BankData(code: '122', name: 'Bank NTB Syariah'),
  BankData(code: '123', name: 'Bank Bali'),
  BankData(code: '124', name: 'Bank NTT'),
  BankData(code: '125', name: 'Bank Maluku Malut'),
  BankData(code: '126', name: 'Bank Papua'),
  BankData(code: '127', name: 'Bank Bengkulu'),
  BankData(code: '128', name: 'Bank Sulawesi Tengah'),
  BankData(code: '129', name: 'Bank Sulawesi Tenggara'),
  BankData(code: '130', name: 'Bank Lampung'),
  BankData(code: '131', name: 'Bank Jambi'),
  BankData(code: '132', name: 'Bank Aceh'),
  BankData(code: '133', name: 'Bank Aceh Syariah'),
  BankData(code: '134', name: 'Bank Sumut'),
  BankData(code: '135', name: 'Bank Nagari (Bank Sumbar)'),
  BankData(code: '146', name: 'Bank Muamalat'),
  BankData(code: '147', name: 'Bank Mestika Dharma'),
  BankData(code: '151', name: 'Bank Sinarmas'),
  BankData(code: '152', name: 'Bank Maspion'),
  BankData(code: '153', name: 'Bank Ganesha'),
  BankData(code: '161', name: 'Bank Ganesha'),
  BankData(code: '167', name: 'Bank QNB Indonesia'),
  BankData(code: '212', name: 'Bank Woori Saudara'),
  BankData(code: '405', name: 'Bank Victoria Syariah'),
  BankData(code: '422', name: 'Bank BRI Agroniaga'),
  BankData(code: '426', name: 'Bank Mega'),
  BankData(code: '441', name: 'Bank Bukopin'),
  BankData(code: '459', name: 'Bank Bisnis Internasional'),
  BankData(code: '466', name: 'Bank SRI Partha'),
  BankData(code: '472', name: 'Bank Jasa Jakarta'),
  BankData(code: '484', name: 'Bank KEB Hana Indonesia'),
  BankData(code: '490', name: 'Bank Yudha Bhakti'),
  BankData(code: '491', name: 'Bank Mitraniaga'),
  BankData(code: '494', name: 'Bank Agroniaga'),
  BankData(code: '498', name: 'Bank SBI Indonesia'),
  BankData(code: '501', name: 'Bank Royal Indonesia'),
  BankData(code: '503', name: 'Bank National Nobu (Bank Alfindo)'),
  BankData(code: '506', name: 'Bank Mega Syariah'),
  BankData(code: '513', name: 'Bank Ina Perdana'),
  BankData(code: '521', name: 'Bank Bukopin Syariah'),
  BankData(code: '523', name: 'Bank Sahabat Sampoerna'),
  BankData(code: '526', name: 'Bank Dinar Indonesia'),
  BankData(code: '531', name: 'Bank Anglomas Internasional'),
  BankData(code: '535', name: 'Bank Kesejahteraan Ekonomi'),
  BankData(code: '547', name: 'Bank BCA Digital (Blu)'),
  BankData(code: '553', name: 'Bank Mayora'),
  BankData(code: '555', name: 'Bank Index Selindo'),
  BankData(code: '558', name: 'Bank Eksekutif'),
  BankData(code: '562', name: 'Bank Shinhan Indonesia'),
  BankData(code: '564', name: 'Bank QNB Indonesia'),
  BankData(code: '567', name: 'Bank Victoria International'),
  BankData(code: '945', name: 'Bank Agris'),

  // Bank Asing
  BankData(code: '031', name: 'Citibank'),
  BankData(code: '032', name: 'JP Morgan Chase Bank'),
  BankData(code: '033', name: 'Bank of America'),
  BankData(code: '034', name: 'ING Indonesia Bank'),
  BankData(code: '036', name: 'Bank Mizuho Indonesia'),
  BankData(code: '042', name: 'Bank of China (Hong Kong) Limited'),
  BankData(code: '045', name: 'Bank Sumitomo Mitsui Indonesia'),
  BankData(code: '047', name: 'Bank Resona Perdania'),
  BankData(code: '048', name: 'Bank Chinatrust Indonesia'),
  BankData(code: '052', name: 'Bank Rabobank International Indonesia'),
  BankData(code: '068', name: 'Bank of Tokyo Mitsubishi UFJ'),
  BankData(code: '076', name: 'Bank BNP Paribas Indonesia'),
  BankData(code: '531', name: 'Bank Capital Indonesia'),

  // Bank Syariah lainnya
  BankData(code: '911', name: 'Bank Aladin Syariah'),
  BankData(code: '422', name: 'Bank BRI Syariah'),
  BankData(code: '424', name: 'Bank Mandiri Syariah'),
  BankData(code: '441', name: 'Bank Bukopin Syariah'),

  // Digital Bank
  BankData(code: '490', name: 'Bank Neo Commerce (BNC)'),
  BankData(code: '213', name: 'Bank Seabank Indonesia'),
  BankData(code: '911', name: 'Bank Allo'),
  BankData(code: '542', name: 'Bank Jago (Gojek)'),
];

/// Helper untuk search bank by name atau code
List<BankData> searchBanks(String query) {
  if (query.isEmpty) return INDONESIA_BANKS;

  final lowerQuery = query.toLowerCase();
  return INDONESIA_BANKS.where((bank) {
    return bank.name.toLowerCase().contains(lowerQuery) ||
        bank.code.contains(query);
  }).toList();
}
