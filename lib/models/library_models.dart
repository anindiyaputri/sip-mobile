class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.copies,
  });

  final int id;
  final String title;
  final String author;
  final String category;
  final int copies;
}

class Member {
  const Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
  });

  final int id;
  final String name;
  final String phone;
  final String email;
}

class Loan {
  const Loan({
    required this.id,
    required this.bookId,
    required this.memberId,
    required this.bookTitle,
    required this.memberName,
    required this.borrowedAt,
    required this.dueAt,
    this.returnedAt,
    this.ownerUserId,
  });

  final int id;
  final int bookId;
  final int memberId;
  final String bookTitle;
  final String memberName;
  final DateTime borrowedAt;
  final DateTime dueAt;
  final DateTime? returnedAt;
  final String? ownerUserId;

  int get quantity => 1;
}
