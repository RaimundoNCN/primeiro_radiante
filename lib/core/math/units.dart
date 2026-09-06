class UnitValue {
  const UnitValue(this.value, this.unit);

  final double value;
  final String unit;

  UnitValue convertTo(String target) {
    final source = _units[unit];
    final destination = _units[target];
    if (source == null ||
        destination == null ||
        source.dimension != destination.dimension) {
      throw ArgumentError('unidades incompatíveis: $unit e $target');
    }
    final base = value * source.scale + source.offset;
    return UnitValue((base - destination.offset) / destination.scale, target);
  }

  UnitValue operator +(UnitValue other) {
    return UnitValue(value + other.convertTo(unit).value, unit);
  }

  @override
  bool operator ==(Object other) =>
      other is UnitValue && other.value == value && other.unit == unit;

  @override
  int get hashCode => Object.hash(value, unit);
}

class _UnitDefinition {
  const _UnitDefinition(this.dimension, this.scale, [this.offset = 0]);

  final String dimension;
  final double scale;
  final double offset;
}

const _units = <String, _UnitDefinition>{
  'm': _UnitDefinition('length', 1),
  'km': _UnitDefinition('length', 1000),
  's': _UnitDefinition('time', 1),
  'min': _UnitDefinition('time', 60),
  'h': _UnitDefinition('time', 3600),
  'K': _UnitDefinition('temperature', 1),
  'C': _UnitDefinition('temperature', 1, 273.15),
};
