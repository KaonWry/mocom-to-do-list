String formatDateTime(DateTime? dt) {
  if (dt == null) return '-';
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  return '$day/$month/${dt.year} • $hour:$minute';
}

String formatRemainingTime(DateTime deadline) {
  final diff = deadline.difference(DateTime.now());
  if (diff.isNegative) return 'Waktu habis!';

  if (diff.inDays > 0) {
    return '${diff.inDays}h ${diff.inHours % 24}j lagi';
  } else if (diff.inHours > 0) {
    return '${diff.inHours}j ${diff.inMinutes % 60}m lagi';
  } else if (diff.inMinutes > 0) {
    return '${diff.inMinutes}m ${diff.inSeconds % 60}d lagi';
  } else {
    return '${diff.inSeconds}d lagi!';
  }
}
