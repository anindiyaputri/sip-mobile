import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/loan_report.dart';
import '../models/library_models.dart';
import 'user_account_store.dart';

class LoanReportPdfService {
  Future<Uint8List> createPdf(
    LoanReportSnapshot report, {
    required AuthenticatedSession session,
    List<Book> books = const [],
    List<Member> members = const [],
  }) async {
    if (session.role != UserRole.admin) {
      throw StateError('Laporan hanya dapat dibuat oleh Admin.');
    }
    final document = pw.Document();
    final reportName = report.period == LoanReportPeriod.daily
        ? 'Harian'
        : 'Bulanan';
    final periodLabel = report.period == LoanReportPeriod.daily
        ? _formatDate(report.selectedDate)
        : '${_monthName(report.selectedDate.month)} ${report.selectedDate.year}';
    final rows = <List<String>>[
      [
        'ID',
        'Tanggal Pinjam',
        'Anggota',
        'Judul Buku',
        'Qty',
        'Jatuh Tempo',
        'Tanggal Kembali',
        'Status',
      ],
      ...report.loans.map((loan) => _loanRow(loan, report)),
    ];
    final bookRows = <List<String>>[
      ['ID', 'Judul', 'Pengarang', 'Kategori', 'Tersedia', 'Jumlah'],
      ...books.map((book) {
        final activeCopies = report.allLoans
            .where((loan) => loan.bookId == book.id && loan.returnedAt == null)
            .fold(0, (total, loan) => total + loan.quantity);
        return [
          '${book.id}',
          book.title,
          book.author,
          book.category,
          '${book.copies - activeCopies}',
          '${book.copies}',
        ];
      }),
    ];
    final memberRows = <List<String>>[
      ['ID', 'Nama', 'Email', 'Telepon'],
      ...members.map(
        (member) => ['${member.id}', member.name, member.email, member.phone],
      ),
    ];

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(28, 30, 28, 34),
        header: (_) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            'SIP MOBILE - Laporan $reportName',
            style: pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
          ),
        ),
        build: (context) => [
          pw.Text(
            'LAPORAN PEMINJAMAN DAN PENGEMBALIAN BUKU SIP MOBILE',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Jenis: $reportName  |  Periode: $periodLabel'),
          pw.Text('Jenis transaksi: ${_eventLabel(report.event)}'),
          pw.Text('Filter status: ${_statusLabel(report.status)}'),
          pw.Text('Tanggal dibuat: ${_formatDate(DateTime.now())}'),
          pw.SizedBox(height: 14),
          pw.Text(
            'Ringkasan',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _summaryItem('Peminjaman', '${report.borrowedCount}'),
              _summaryItem('Buku dipinjam', '${report.booksBorrowed}'),
              _summaryItem('Anggota unik', '${report.uniqueBorrowers}'),
              _summaryItem('Pengembalian', '${report.returnedCount}'),
              _summaryItem('Masih dipinjam', '${report.activeCount}'),
              _summaryItem('Terlambat', '${report.overdueCount}'),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Daftar transaksi (satu transaksi berisi satu eksemplar buku)',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            data: rows,
            headerCount: 1,
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            headerStyle: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 5,
            ),
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
            columnWidths: {
              0: const pw.FixedColumnWidth(30),
              1: const pw.FixedColumnWidth(62),
              2: const pw.FixedColumnWidth(105),
              3: const pw.FlexColumnWidth(3),
              4: const pw.FixedColumnWidth(28),
              5: const pw.FixedColumnWidth(62),
              6: const pw.FixedColumnWidth(62),
              7: const pw.FixedColumnWidth(62),
            },
          ),
          if (report.loans.isEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Tidak ada transaksi untuk periode dan filter ini.'),
          ],
          pw.SizedBox(height: 14),
          pw.Text(
            'Rekap Data Buku',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            data: bookRows,
            headerCount: 1,
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerStyle: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Rekap Data Anggota',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            data: memberRows,
            headerCount: 1,
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerStyle: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _summaryItem(String label, String value) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: pw.BoxDecoration(
      color: PdfColors.blue50,
      border: pw.Border.all(color: PdfColors.blue100),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    child: pw.Text('$label: $value', style: const pw.TextStyle(fontSize: 8)),
  );

  List<String> _loanRow(Loan loan, LoanReportSnapshot report) => [
    '${loan.id}',
    _formatDate(loan.borrowedAt),
    '${loan.memberName} (ID ${loan.memberId})',
    loan.bookTitle,
    '${loan.quantity}',
    _formatDate(loan.dueAt),
    loan.returnedAt == null ? '-' : _formatDate(loan.returnedAt!),
    _statusLabel(report.statusOf(loan)),
  ];

  String _statusLabel(LoanReportStatus status) => switch (status) {
    LoanReportStatus.all => 'Semua',
    LoanReportStatus.borrowed => 'Dipinjam',
    LoanReportStatus.returned => 'Dikembalikan',
    LoanReportStatus.overdue => 'Terlambat',
  };

  String _eventLabel(LoanReportEvent event) => switch (event) {
    LoanReportEvent.all => 'Peminjaman dan pengembalian',
    LoanReportEvent.borrowed => 'Peminjaman',
    LoanReportEvent.returned => 'Pengembalian',
  };

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
