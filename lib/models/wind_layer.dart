/// A computed wind for one altitude layer.
///
/// [headingDeg] is the meteorological "wind from" direction (degrees true).
class WindLayer {
  final double heightFt;
  final double headingDeg;
  final double speedKts;

  const WindLayer(this.heightFt, this.headingDeg, this.speedKts);
}
