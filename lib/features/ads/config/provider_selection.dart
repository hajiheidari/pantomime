import '../../../core/store/app_store.dart';
import 'remote_config.dart';

/// FNV-1a 32-bit hash: tiny, stable across platforms and app versions.
int fnv1a32(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash;
}

/// Deterministically assigns an install to one provider of an A/B split.
/// The same install id always lands in the same bucket (0–99), so an
/// install keeps its network for the whole test.
String pickFromSplit(Map<String, int> split, String installId, AppStore store) {
  final bucket = fnv1a32('$installId:${store.name}') % 100;
  final entries = split.entries.where((e) => e.value > 0).toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  var acc = 0;
  for (final e in entries) {
    acc += e.value;
    if (bucket < acc) return e.key;
  }
  return entries.last.key;
}

/// Ordered list of providers to use for [store]:
/// A/B assignment (or `active_provider`) first, then `fallback_chain`,
/// keeping only networks compiled into this build, allowed on this store
/// and not given up on in this session.
List<String> providerChain({
  required AdsConfig ads,
  required AppStore store,
  required String installId,
  required Set<String> compiled,
  Set<String> failed = const {},
}) {
  final split = ads.abSplit[store];
  final primary = split != null && split.isNotEmpty
      ? pickFromSplit(split, installId, store)
      : ads.activeProvider[store];
  final ordered = <String>[
    ?primary,
    ...?ads.fallbackChain[store],
    // If an A/B provider is missing from this build, the store's active
    // provider is the next best choice.
    ?ads.activeProvider[store],
  ];
  final out = <String>[];
  for (final p in ordered) {
    if (out.contains(p)) continue;
    if (!compiled.contains(p) || failed.contains(p)) continue;
    if (p == 'admob' && !store.allowsGooglePlayServices) continue;
    out.add(p);
  }
  return out;
}
