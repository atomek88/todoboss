// static utility function that checks if Type Date is yesterday
bool isYesterday(DateTime date) {
  final today = DateTime.now();
  final yesterday = today.subtract(const Duration(days: 1));
  return date.isAtSameMomentAs(yesterday);
}
