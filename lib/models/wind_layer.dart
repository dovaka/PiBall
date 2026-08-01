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
