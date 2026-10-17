import 'library_models.dart';

enum LoanReportPeriod { daily, monthly }

enum LoanReportStatus { all, borrowed, returned, overdue }

class LoanReportSnapshot {
  LoanReportSnapshot({
    required List<Loan> loans,
    required this.period,
    required this.selectedDate,
    required this.status,
    DateTime? asOf,
  }) : _loans = List<Loan>.unmodifiable(loans),
       asOf = asOf ?? DateTime.now();

  final List<Loan> _loans;
  final LoanReportPeriod period;
  final DateTime selectedDate;
  final LoanReportStatus status;
  final DateTime asOf;

  DateTime get periodStart => period == LoanReportPeriod.daily
      ? _dayStart(selectedDate)
      : DateTime(selectedDate.year, selectedDate.month);

  DateTime get periodEndExclusive => period == LoanReportPeriod.daily
      ? periodStart.add(const Duration(days: 1))
      : DateTime(selectedDate.year, selectedDate.month + 1);

  List<Loan> get loans {
    final matching = _loans.where(_isInPeriod).toList()
      ..sort((a, b) {
        final dateOrder = a.borrowedAt.compareTo(b.borrowedAt);
        return dateOrder != 0 ? dateOrder : a.id.compareTo(b.id);
      });
    if (status == LoanReportStatus.all) return matching;
    return matching.where((loan) => statusOf(loan) == status).toList();
  }

  int get borrowedCount =>
      _loans.where((loan) => _isWithin(loan.borrowedAt)).length;

  int get booksBorrowed => _loans
      .where((loan) => _isWithin(loan.borrowedAt))
      .fold(0, (total, loan) => total + loan.quantity);

  int get uniqueBorrowers => _loans
      .where((loan) => _isWithin(loan.borrowedAt))
      .map((loan) => loan.memberId)
      .toSet()
      .length;

  int get returnedCount => _loans
      .where((loan) => loan.returnedAt != null && _isWithin(loan.returnedAt!))
      .length;

  int get activeCount => _loans
      .where((loan) => _isWithin(loan.borrowedAt) && loan.returnedAt == null)
      .length;

  int get overdueCount => _loans
      .where(
        (loan) =>
            _isInPeriod(loan) && statusOf(loan) == LoanReportStatus.overdue,
      )
      .length;

  LoanReportStatus statusOf(Loan loan) {
    if (loan.returnedAt != null) {
      return _dayStart(loan.returnedAt!).isAfter(_dayStart(loan.dueAt))
          ? LoanReportStatus.overdue
          : LoanReportStatus.returned;
    }
    return _dayStart(asOf).isAfter(_dayStart(loan.dueAt))
        ? LoanReportStatus.overdue
        : LoanReportStatus.borrowed;
  }

  bool _isInPeriod(Loan loan) =>
      _isWithin(loan.borrowedAt) ||
      (loan.returnedAt != null && _isWithin(loan.returnedAt!));

  bool _isWithin(DateTime date) {
    final value = _dayStart(date);
    return !value.isBefore(periodStart) && value.isBefore(periodEndExclusive);
  }

  static DateTime _dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
