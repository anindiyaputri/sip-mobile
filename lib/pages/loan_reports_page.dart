import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/library_models.dart';
import '../models/loan_report.dart';
import '../services/loan_report_pdf_service.dart';

class LoanReportsPage extends StatefulWidget {
  const LoanReportsPage({super.key, required this.loans});

  final List<Loan> loans;

  @override
  State<LoanReportsPage> createState() => _LoanReportsPageState();
}

class _LoanReportsPageState extends State<LoanReportsPage> {
  final _pdfService = LoanReportPdfService();
  LoanReportPeriod _period = LoanReportPeriod.daily;
  LoanReportStatus _status = LoanReportStatus.all;
  DateTime _selectedDate = DateTime.now();
  bool _isExporting = false;

  Future<void> _selectPeriodDate() async {
    if (_period == LoanReportPeriod.monthly) {
      final picked = await _selectMonthAndYear();
      if (picked == null || !mounted) return;
      setState(() => _selectedDate = picked);
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pilih tanggal laporan',
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
  }

  Future<DateTime?> _selectMonthAndYear() {
    var selectedMonth = _selectedDate.month;
    var selectedYear = _selectedDate.year;
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pilih bulan dan tahun'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedMonth,
                decoration: const InputDecoration(labelText: 'Bulan'),
                items: [
                  for (var month = 1; month <= months.length; month++)
                    DropdownMenuItem(
                      value: month,
                      child: Text(months[month - 1]),
                    ),
                ],
                onChanged: (month) {
                  if (month != null) {
                    setDialogState(() => selectedMonth = month);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selectedYear,
                menuMaxHeight: 320,
                decoration: const InputDecoration(labelText: 'Tahun'),
                items: [
                  for (var year = 2000; year <= 2100; year++)
                    DropdownMenuItem(value: year, child: Text('$year')),
                ],
                onChanged: (year) {
                  if (year != null) {
                    setDialogState(() => selectedYear = year);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext)
                      .pop(DateTime(selectedYear, selectedMonth)),
              child: const Text('Pilih'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf({required bool share}) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final report = _buildReport();
      final bytes = await _pdfService.createPdf(report);
      final filename = _fileName(report);
      if (share) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: filename,
          subject: 'Laporan SIP Mobile',
          body: 'Laporan peminjaman dan pengembalian buku.',
        );
      } else {
        await Printing.layoutPdf(
          name: filename,
          format: PdfPageFormat.a4.landscape,
          onLayout: (_) async => bytes,
        );
      }
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('PDF gagal dibuat atau dibuka: $error')),
        );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  LoanReportSnapshot _buildReport() => LoanReportSnapshot(
    loans: widget.loans,
    period: _period,
    selectedDate: _selectedDate,
    status: _status,
  );

  String _fileName(LoanReportSnapshot report) {
    final period = report.period == LoanReportPeriod.daily
        ? '${report.selectedDate.year}-'
              '${report.selectedDate.month.toString().padLeft(2, '0')}-'
              '${report.selectedDate.day.toString().padLeft(2, '0')}'
        : '${report.selectedDate.year}-'
              '${report.selectedDate.month.toString().padLeft(2, '0')}';
    return 'laporan-peminjaman-$period.pdf';
  }

  @override
  Widget build(BuildContext context) {
    final report = _buildReport();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        children: [
          Card(
            margin: EdgeInsets.zero,
            elevation: 1,
            shadowColor: const Color(0x1417233D),
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE8EDF5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<LoanReportPeriod>(
                    segments: const [
                      ButtonSegment(
                        value: LoanReportPeriod.daily,
                        label: Text('Harian'),
                        icon: Icon(Icons.today_outlined),
                      ),
                      ButtonSegment(
                        value: LoanReportPeriod.monthly,
                        label: Text('Bulanan'),
                        icon: Icon(Icons.calendar_month_outlined),
                      ),
                    ],
                    selected: {_period},
                    onSelectionChanged: (selection) {
                      setState(() => _period = selection.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _selectPeriodDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      _period == LoanReportPeriod.daily
                          ? _formatDate(_selectedDate)
                          : '${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<LoanReportStatus>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Filter status transaksi',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: LoanReportStatus.all,
                        child: Text('Semua status'),
                      ),
                      DropdownMenuItem(
                        value: LoanReportStatus.borrowed,
                        child: Text('Dipinjam'),
                      ),
                      DropdownMenuItem(
                        value: LoanReportStatus.returned,
                        child: Text('Dikembalikan'),
                      ),
                      DropdownMenuItem(
                        value: LoanReportStatus.overdue,
                        child: Text('Terlambat'),
                      ),
                    ],
                    onChanged: (status) {
                      if (status != null) setState(() => _status = status);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _period == LoanReportPeriod.daily
                ? 'Ringkasan Harian'
                : 'Ringkasan Bulanan',
            style: const TextStyle(
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 9) / 2;
              return Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _summaryCard(
                    context,
                    cardWidth,
                    'Transaksi peminjaman',
                    report.borrowedCount,
                    Icons.call_made_rounded,
                  ),
                  _summaryCard(
                    context,
                    cardWidth,
                    'Buku dipinjam',
                    report.booksBorrowed,
                    Icons.menu_book_rounded,
                  ),
                  _summaryCard(
                    context,
                    cardWidth,
                    'Anggota unik',
                    report.uniqueBorrowers,
                    Icons.people_alt_outlined,
                  ),
                  _summaryCard(
                    context,
                    cardWidth,
                    'Transaksi pengembalian',
                    report.returnedCount,
                    Icons.assignment_return_outlined,
                  ),
                  _summaryCard(
                    context,
                    cardWidth,
                    'Masih dipinjam',
                    report.activeCount,
                    Icons.bookmark_border_rounded,
                  ),
                  _summaryCard(
                    context,
                    cardWidth,
                    'Terlambat',
                    report.overdueCount,
                    Icons.warning_amber_rounded,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Daftar Transaksi',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_isExporting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Setiap ID transaksi mencatat satu eksemplar buku.',
            style: TextStyle(
              fontSize: 12,
              height: 1.25,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 8),
          if (report.loans.isEmpty)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Tidak ada transaksi untuk periode dan filter ini.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...report.loans.map(
              (loan) => _transactionCard(context, report, loan),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExporting
                      ? null
                      : () => _exportPdf(share: false),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Cetak PDF'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isExporting
                      ? null
                      : () => _exportPdf(share: true),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Bagikan PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    double width,
    String label,
    int value,
    IconData icon,
  ) {
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        shadowColor: const Color(0x1417233D),
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE8EDF5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transactionCard(
    BuildContext context,
    LoanReportSnapshot report,
    Loan loan,
  ) {
    final status = report.statusOf(loan);
    final primary = Theme.of(context).colorScheme.primary;
    final statusText = switch (status) {
      LoanReportStatus.all => 'Semua',
      LoanReportStatus.borrowed => 'Dipinjam',
      LoanReportStatus.returned => 'Dikembalikan',
      LoanReportStatus.overdue => 'Terlambat',
    };
    final statusColor = status == LoanReportStatus.overdue
        ? const Color(0xFFB54708)
        : primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shadowColor: const Color(0x1417233D),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE8EDF5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Transaksi #${loan.id}  •  ${loan.bookTitle}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${loan.memberName} (ID ${loan.memberId})  |  '
              '${loan.quantity} buku',
              style: const TextStyle(
                fontSize: 12,
                height: 1.25,
                color: Color(0xFF647087),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Pinjam ${_formatDate(loan.borrowedAt)}  |  '
              'Jatuh tempo ${_formatDate(loan.dueAt)}',
              style: const TextStyle(
                fontSize: 12,
                height: 1.25,
                color: Color(0xFF667085),
              ),
            ),
            if (loan.returnedAt != null) ...[
              const SizedBox(height: 3),
              Text(
                'Dikembalikan ${_formatDate(loan.returnedAt!)}',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  color: Color(0xFF667085),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _monthName(int month) => const [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ][month - 1];
}
