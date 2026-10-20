/// The ten bank integrations supported by the Lanka Offers ingestion engine.
///
/// Offers carry the lowercase [code] (`hnb`); the public `/api/banks` directory
/// supplies live counts. Names and monograms are text only: no bank logo
/// assets are bundled because none are licensed for this app.
class CanonicalBank {
  final String code;
  final String name;
  final String short;
  final String? nameSi;
  final String? nameTa;

  const CanonicalBank(
    this.code,
    this.name,
    this.short, {
    this.nameSi,
    this.nameTa,
  });

  String localizedName(String? languageCode) {
    if (languageCode == 'si' && nameSi != null) return nameSi!;
    if (languageCode == 'ta' && nameTa != null) return nameTa!;
    return name;
  }
}

class CanonicalBanks {
  CanonicalBanks._();

  static const List<CanonicalBank> all = [
    CanonicalBank(
      'hnb',
      'Hatton National Bank',
      'HNB',
      nameSi: 'හැටන් නැෂනල් බැංකුව',
      nameTa: 'ஹற்றன் நஷனல் வங்கி',
    ),
    CanonicalBank(
      'boc',
      'Bank of Ceylon',
      'BOC',
      nameSi: 'ලංකා බැංකුව',
      nameTa: 'இலங்கை வங்கி',
    ),
    CanonicalBank(
      'peoples',
      "People's Bank",
      'PB',
      nameSi: 'මහජන බැංකුව',
      nameTa: 'மக்கள் வங்கி',
    ),
    CanonicalBank(
      'nsb',
      'National Savings Bank',
      'NSB',
      nameSi: 'ජාතික ඉතිරි කිරීමේ බැංකුව',
      nameTa: 'தேசிய சேமிப்பு வங்கி',
    ),
    CanonicalBank(
      'sampath',
      'Sampath Bank',
      'SB',
      nameSi: 'සම්පත් බැංකුව',
      nameTa: 'சம்பத் வங்கி',
    ),
    CanonicalBank(
      'seylan',
      'Seylan Bank',
      'SYL',
      nameSi: 'සෙලාන් බැංකුව',
      nameTa: 'செய்லான் வங்கி',
    ),
    CanonicalBank(
      'ndb',
      'NDB Bank',
      'NDB',
      nameSi: 'ජාතික සංවර්ධන බැංකුව',
      nameTa: 'தேசிய அபிவிருத்தி வங்கி',
    ),
    CanonicalBank(
      'dfcc',
      'DFCC Bank',
      'DFCC',
      nameSi: 'ඩී.එෆ්.සී.සී. බැංකුව',
      nameTa: 'டி.எப்.சி.சி வங்கி',
    ),
    CanonicalBank(
      'pabc',
      'Pan Asia Bank',
      'PABC',
      nameSi: 'පෑන් ඒෂියා බැංකුව',
      nameTa: 'பான் ஏசியா வங்கி',
    ),
    CanonicalBank(
      'combank',
      'Commercial Bank',
      'ComBank',
      nameSi: 'කොමර්ෂල් බැංකුව',
      nameTa: 'கொமர்ஷல் வங்கி',
    ),
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

  static String nameFor(String? codeOrName, [String? languageCode]) {
    final b = lookup(codeOrName);
    if (b != null) return b.localizedName(languageCode);
    return codeOrName ?? '';
  }
}
