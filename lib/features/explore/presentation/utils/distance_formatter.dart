String formatDistanceKm(double? distanceKm) {
  if (distanceKm == null) return '';
  if (distanceKm < 0) return '';
  if (distanceKm < 1) return '${(distanceKm * 1000).round()} m';
  return '${distanceKm.toStringAsFixed(1)} km';
}
