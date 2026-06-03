/// One sighting of the balloon: seconds since launch, plus the true-north
/// azimuth and the elevation angle above the horizon (both in degrees).
class Reading {
  final double time;
  final double az;
  final double el;

  const Reading(this.time, this.az, this.el);
}
