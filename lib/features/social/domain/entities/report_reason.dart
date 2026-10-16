/// Why someone is being reported. The [apiValue]s match the API's enum.
enum ReportReason {
  spam('spam', 'Spam'),
  harassment('harassment', 'Harassment or bullying'),
  inappropriate('inappropriate', 'Inappropriate content'),
  impersonation('impersonation', 'Pretending to be someone else'),
  other('other', 'Something else');

  final String apiValue;
  final String label;
  const ReportReason(this.apiValue, this.label);
}
