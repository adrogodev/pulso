/// Banda de frecuencia del ecualizador con su ganancia actual.
class EqualizerBand {
  final int index;
  final double centerHz;
  final double minDb;
  final double maxDb;
  final double gainDb;

  const EqualizerBand({
    required this.index,
    required this.centerHz,
    required this.minDb,
    required this.maxDb,
    this.gainDb = 0,
  });

  EqualizerBand copyWith({double? gainDb}) {
    return EqualizerBand(
      index: index,
      centerHz: centerHz,
      minDb: minDb,
      maxDb: maxDb,
      gainDb: gainDb ?? this.gainDb,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EqualizerBand &&
          other.index == index &&
          other.centerHz == centerHz &&
          other.minDb == minDb &&
          other.maxDb == maxDb &&
          other.gainDb == gainDb);

  @override
  int get hashCode => Object.hash(index, centerHz, minDb, maxDb, gainDb);
}
