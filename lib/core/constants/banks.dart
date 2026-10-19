/// The ten bank integrations supported by the Lanka Offers ingestion engine.
///
/// Offers carry the lowercase [code] (`hnb`); the public `/api/banks` directory
/// supplies live counts. Names and monograms are text only: no bank logo
/// assets are bundled because none are licensed for this app.
class CanonicalBank {
  final String code;
  final String name;
  final String short;

  const CanonicalBank(this.code, this.name, this.short);
}

class CanonicalBanks {
  CanonicalBanks._();

  static const List<CanonicalBank> all = [
    CanonicalBank('hnb', 'Hatton National Bank', 'HNB'),
    CanonicalBank('boc', 'Bank of Ceylon', 'BOC'),
    CanonicalBank('peoples', "People's Bank", 'PB'),
    CanonicalBank('nsb', 'National Savings Bank', 'NSB'),
    CanonicalBank('sampath', 'Sampath Bank', 'SB'),
    CanonicalBank('seylan', 'Seylan Bank', 'SYL'),
    CanonicalBank('ndb', 'NDB Bank', 'NDB'),
    CanonicalBank('dfcc', 'DFCC Bank', 'DFCC'),
    CanonicalBank('pabc', 'Pan Asia Bank', 'PABC'),
    CanonicalBank('combank', 'Commercial Bank', 'ComBank'),
  ];

  /// Matches a bank code ("hnb") or a canonical display name.
  static CanonicalBank? lookup(String? codeOrName) {
    if (codeOrName == null || codeOrName.trim().isEmpty) return null;
    final key = codeOrName.trim().toLowerCase();
    for (final b in all) {
      if (b.code == key || b.name.toLowerCase() == key) return b;
    }
    return null;
  }

  static String nameFor(String? codeOrName) =>
      lookup(codeOrName)?.name ?? (codeOrName ?? '');
}
