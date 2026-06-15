/// A computed wind for one altitude layer.
///
/// [headingDeg] is the meteorological "wind from" direction (degrees true).
/// [lowElevation] is true when the sighting that produced this layer was at too
/// shallow an angle for the slant geometry to be trustworthy.
class WindLayer {
  final double heightFt;
  final double headingDeg;
  final double speedKts;
  final bool lowElevation;

  const WindLayer(
    this.heightFt,
    this.headingDeg,
    this.speedKts, {
    this.lowElevation = false,
  });
}
