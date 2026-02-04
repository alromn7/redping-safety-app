class StarlinkCarrierUtils {
  static bool isStarlinkPartnerCarrier(String carrierName) {
    final normalized = carrierName.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'unknown') return false;

    // Heuristic list of known/expected Starlink partner carriers.
    // Expand safely over time as partnerships roll out.
    const partners = <String>[
      'telstra',
      'globe',
      't-mobile',
      'tmobile',
      'one nz',
      'one new zealand',
      'rogers',
      'kddi',
      'optus',
    ];

    for (final p in partners) {
      if (normalized.contains(p)) return true;
    }
    return false;
  }
}
