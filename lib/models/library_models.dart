import 'package:hive/hive.dart';

// --- CORE MODELS ---

class Category extends HiveObject {
  int categoryId;
  String categoryName;
  Category({required this.categoryId, required this.categoryName});
}

class Publisher extends HiveObject {
  int publisherId;
  String publisherName;
  String publicationLanguage;
  String publicationType;
  Publisher({required this.publisherId, required this.publisherName, required this.publicationLanguage, required this.publicationType});
}

class Location extends HiveObject {
  int locationId;
  String shelfNo;
  String shelfName;
  String floorNo;
  Location({required this.locationId, required this.shelfNo, required this.shelfName, required this.floorNo});
}

class Book extends HiveObject {
  int bookId;
  String isbnCode;
  String bookTitle;
  int categoryId;
  int publisherId;
  int authorId;
  int publicationYear;
  String bookEdition;
  int copiesTotal;
  int copiesAvailable;
  int locationId;
  Book({
    required this.bookId,
    required this.isbnCode,
    required this.bookTitle,
    required this.categoryId,
    required this.publisherId,
    required this.authorId,
    required this.publicationYear,
    required this.bookEdition,
    required this.copiesTotal,
    required this.copiesAvailable,
    required this.locationId,
  });
}

class Author extends HiveObject {
  int authorId;
  String firstName;
  String lastName;
  Author({required this.authorId, required this.firstName, required this.lastName});
  String get fullName => '$firstName $lastName';
}

class Member extends HiveObject {
  int memberId;
  String firstName;
  String lastName;
  String city;
  String mobileNo;
  String emailId;
  String dateOfBirth;
  int activeStatusId;
  Member({required this.memberId, required this.firstName, required this.lastName, required this.city, required this.mobileNo, required this.emailId, required this.dateOfBirth, required this.activeStatusId});
  String get fullName => '$firstName $lastName';
}

// --- ADAPTERS ---
// Manual adapters are used here to avoid build_runner dependency, keeping the project simple.

class CategoryAdapter extends TypeAdapter<Category> {
  @override final typeId = 0;
  @override Category read(BinaryReader reader) => Category(categoryId: reader.read(), categoryName: reader.read());
  @override void write(BinaryWriter writer, Category obj) { writer.write(obj.categoryId); writer.write(obj.categoryName); }
}

class PublisherAdapter extends TypeAdapter<Publisher> {
  @override final typeId = 1;
  @override Publisher read(BinaryReader reader) => Publisher(publisherId: reader.read(), publisherName: reader.read(), publicationLanguage: reader.read(), publicationType: reader.read());
  @override void write(BinaryWriter writer, Publisher obj) { writer.write(obj.publisherId); writer.write(obj.publisherName); writer.write(obj.publicationLanguage); writer.write(obj.publicationType); }
}

class LocationAdapter extends TypeAdapter<Location> {
  @override final typeId = 2;
  @override Location read(BinaryReader reader) => Location(locationId: reader.read(), shelfNo: reader.read(), shelfName: reader.read(), floorNo: reader.read());
  @override void write(BinaryWriter writer, Location obj) { writer.write(obj.locationId); writer.write(obj.shelfNo); writer.write(obj.shelfName); writer.write(obj.floorNo); }
}

class BookAdapter extends TypeAdapter<Book> {
  @override final typeId = 3;
  @override Book read(BinaryReader reader) => Book(
    bookId: reader.read(),
    isbnCode: reader.read(),
    bookTitle: reader.read(),
    categoryId: reader.read(),
    publisherId: reader.read(),
    authorId: reader.read(),
    publicationYear: reader.read(),
    bookEdition: reader.read(),
    copiesTotal: reader.read(),
    copiesAvailable: reader.read(),
    locationId: reader.read(),
  );
  @override void write(BinaryWriter writer, Book obj) {
    writer.write(obj.bookId);
    writer.write(obj.isbnCode);
    writer.write(obj.bookTitle);
    writer.write(obj.categoryId);
    writer.write(obj.publisherId);
    writer.write(obj.authorId);
    writer.write(obj.publicationYear);
    writer.write(obj.bookEdition);
    writer.write(obj.copiesTotal);
    writer.write(obj.copiesAvailable);
    writer.write(obj.locationId);
  }
}

class AuthorAdapter extends TypeAdapter<Author> {
  @override final typeId = 4;
  @override Author read(BinaryReader reader) => Author(authorId: reader.read(), firstName: reader.read(), lastName: reader.read());
  @override void write(BinaryWriter writer, Author obj) { writer.write(obj.authorId); writer.write(obj.firstName); writer.write(obj.lastName); }
}

class MemberAdapter extends TypeAdapter<Member> {
  @override final typeId = 5; // Changed from 6 to 5 for sequence
  @override Member read(BinaryReader reader) => Member(memberId: reader.read(), firstName: reader.read(), lastName: reader.read(), city: reader.read(), mobileNo: reader.read(), emailId: reader.read(), dateOfBirth: reader.read(), activeStatusId: reader.read());
  @override void write(BinaryWriter writer, Member obj) { writer.write(obj.memberId); writer.write(obj.firstName); writer.write(obj.lastName); writer.write(obj.city); writer.write(obj.mobileNo); writer.write(obj.emailId); writer.write(obj.dateOfBirth); writer.write(obj.activeStatusId); }
}


class BookIssue extends HiveObject {
  int issueId;
  int bookId;
  int memberId;
  String issueDate;
  String returnDate;
  bool isReturned;
  BookIssue({required this.issueId, required this.bookId, required this.memberId, required this.issueDate, required this.returnDate, required this.isReturned});
}

class BookIssueAdapter extends TypeAdapter<BookIssue> {
  @override final typeId = 6;
  @override BookIssue read(BinaryReader reader) => BookIssue(issueId: reader.read(), bookId: reader.read(), memberId: reader.read(), issueDate: reader.read(), returnDate: reader.read(), isReturned: reader.read());
  @override void write(BinaryWriter writer, BookIssue obj) { writer.write(obj.issueId); writer.write(obj.bookId); writer.write(obj.memberId); writer.write(obj.issueDate); writer.write(obj.returnDate); writer.write(obj.isReturned); }
}



class AppUser extends HiveObject {
  String username;
  String password;
  String? profilePicBase64;
  AppUser({required this.username, required this.password, this.profilePicBase64});
}

class AppUserAdapter extends TypeAdapter<AppUser> {
  @override final typeId = 7;
  @override AppUser read(BinaryReader reader) => AppUser(username: reader.read(), password: reader.read(), profilePicBase64: reader.read());
  @override void write(BinaryWriter writer, AppUser obj) { writer.write(obj.username); writer.write(obj.password); writer.write(obj.profilePicBase64); }
}

