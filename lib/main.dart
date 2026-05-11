import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/library_models.dart';
import 'theme/app_theme.dart';

// --- DATABASE SERVICE ---
class DatabaseService {
  static String? user;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(PublisherAdapter());
    Hive.registerAdapter(LocationAdapter());
    Hive.registerAdapter(BookAdapter());
    Hive.registerAdapter(AuthorAdapter());
    Hive.registerAdapter(MemberAdapter());
    Hive.registerAdapter(BookIssueAdapter());
    Hive.registerAdapter(AppUserAdapter());
    await Hive.openBox<AppUser>('users');
  }

  static Future<void> open(String name) async {
    user = name.trim().toLowerCase();
    await Hive.openBox('cat_$user');
    await Hive.openBox('pub_$user');
    await Hive.openBox('loc_$user');
    await Hive.openBox('books_$user');
    await Hive.openBox('auth_$user');
    await Hive.openBox('mem_$user');
    await Hive.openBox('iss_$user');

    if (box('cat').isEmpty) {
      box('cat').add(Category(categoryId: 1, categoryName: 'Computer Science'));
    }
    if (box('auth').isEmpty) {
      box('auth').add(Author(authorId: 1, firstName: 'Majid', lastName: 'ALi'));
    }
    if (box('pub').isEmpty) {
      box('pub').add(Publisher(publisherId: 1, publisherName: 'Tech Press', publicationLanguage: 'English', publicationType: 'Academic'));
    }
    if (box('loc').isEmpty) {
      box('loc').add(Location(locationId: 1, shelfNo: 'A1', shelfName: 'Main Shelf', floorNo: '1'));
    }
  }

  static Box box(String n) => Hive.box('${n}_$user');

  static int nextId(String n, String field) {
    final b = box(n);
    if (b.isEmpty) return 1;
    final ids = b.values.map((e) {
      try {
        return (e as dynamic).toJson()[field] as int;
      } catch (_) {
        // Fallback for models without toJson or complex types
        if (e is Category) return e.categoryId;
        if (e is Publisher) return e.publisherId;
        if (e is Location) return e.locationId;
        if (e is Book) return e.bookId;
        if (e is Author) return e.authorId;
        if (e is Member) return e.memberId;
        return 0;
      }
    }).toList();
    if (ids.isEmpty) return 1;
    return ids.reduce((a, b) => a > b ? a : b) + 1;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    ),
  );
}

// --- AUTH WRAPPER ---
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? login;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('current_user');
    if (savedUser != null) {
      await DatabaseService.open(savedUser);
      setState(() => login = true);
    } else {
      setState(() => login = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (login == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (login!) {
      return const MainShell();
    } else {
      return LoginScreen(
        onLogin: (u) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_user', u.username);
          await DatabaseService.open(u.username);
          setState(() => login = true);
        },
      );
    }
  }
}

// --- LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  final Function(AppUser) onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final uC = TextEditingController();
  final pC = TextEditingController();
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.library_books,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                  const Text(
                    'LibMaster',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(error!, style: const TextStyle(color: Colors.red)),
                    ),
                  TextField(
                    controller: uC,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pC,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      final username = uC.text.trim().toLowerCase();
                      if (username.isEmpty || pC.text.isEmpty) {
                        setState(() => error = "Please fill all fields");
                        return;
                      }

                      final b = Hive.box<AppUser>('users');
                      final u = b.values.cast<AppUser?>().firstWhere(
                            (x) => x?.username.toLowerCase() == username,
                            orElse: () => null,
                          );
                      
                      if (u != null && u.password != pC.text) {
                        setState(() => error = "Invalid password");
                        return;
                      }
                      
                      final finalU = u ?? AppUser(username: username, password: pC.text);
                      if (u == null) b.add(finalU);
                      widget.onLogin(finalU);
                    },
                    child: const Text('Login / Sign Up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- MAIN SHELL ---
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int idx = 0;
  final screens = [const Dash(), const Books(), const Members()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(['Dashboard', 'Books', 'Members'][idx]),
      ),
      drawer: Drawer(
        child: ValueListenableBuilder(
          valueListenable: Hive.box<AppUser>('users').listenable(),
          builder: (c, Box<AppUser> b, _) {
            final cur = b.values.firstWhere((x) => x.username == DatabaseService.user);
            return ListView(
              children: [
                UserAccountsDrawerHeader(
                  currentAccountPicture: GestureDetector(
                    onTap: _pick,
                    child: CircleAvatar(
                      backgroundImage: cur.profilePicBase64 != null
                          ? MemoryImage(base64Decode(cur.profilePicBase64!))
                          : null,
                      child: cur.profilePicBase64 == null
                          ? const Icon(Icons.camera_alt)
                          : null,
                    ),
                  ),
                  accountName: Text(cur.username),
                  accountEmail: const Text('Administrator'),
                ),
                _drawerTile('Categories', 'cat'),
                _drawerTile('Publishers', 'pub'),
                _drawerTile('Locations', 'loc'),
                _drawerTile('Authors', 'auth'),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout'),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('current_user');
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (c) => const AuthWrapper()),
                      );
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: screens[idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Books'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Members'),
        ],
      ),
      floatingActionButton: idx == 0
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => idx == 1 ? const AddBook() : const AddMem()),
              ),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _drawerTile(String t, String k) {
    return ListTile(
      leading: const Icon(Icons.list),
      title: Text(t),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => GenericCRUD(title: t, boxKey: k)),
        );
      },
    );
  }

  void _pick() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) {
      final u = Hive.box<AppUser>('users').values.firstWhere((x) => x.username == DatabaseService.user);
      u.profilePicBase64 = base64Encode(await img.readAsBytes());
      await u.save();
    }
  }
}

// --- DASHBOARD ---
class Dash extends StatelessWidget {
  const Dash({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _Stat('Books', 'books', Icons.book, Colors.indigo),
        _Stat('Members', 'mem', Icons.people, AppTheme.secondaryColor),
        _Stat('Categories', 'cat', Icons.category, Colors.orange),
        _Stat('Publishers', 'pub', Icons.business, Colors.teal),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String t, k;
  final IconData i;
  final Color c;

  const _Stat(this.t, this.k, this.i, this.c);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: DatabaseService.box(k).listenable(),
      builder: (ctx, Box b, _) => Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(i, color: c, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              '${b.length}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              t,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// --- LISTS ---
class Books extends StatefulWidget {
  const Books({super.key});

  @override
  State<Books> createState() => _BooksState();
}

class _BooksState extends State<Books> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => search = v),
            decoration: InputDecoration(
              hintText: 'Search by title...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: DatabaseService.box('books').listenable(),
            builder: (ctx, Box b, _) {
              final list = b.values.where((x) => (x as Book).bookTitle.toLowerCase().contains(search.toLowerCase())).toList();
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final bk = list[i] as Book;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.book, color: Colors.indigo),
                      ),
                      title: Text(bk.bookTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ISBN: ${bk.isbnCode}'),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                DatabaseService.box('auth').values.firstWhere((x) => (x as Author).authorId == bk.authorId, orElse: () => Author(authorId: 0, firstName: 'Unknown', lastName: '')).fullName,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.category, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                DatabaseService.box('cat').values.firstWhere((x) => (x as Category).categoryId == bk.categoryId, orElse: () => Category(categoryId: 0, categoryName: 'Unknown')).categoryName,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (c) => AddBook(book: bk)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => bk.delete(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class Members extends StatelessWidget {
  const Members({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: DatabaseService.box('mem').listenable(),
      builder: (c, Box b, _) => ListView.builder(
        itemCount: b.length,
        itemBuilder: (c, i) {
          final m = b.getAt(i) as Member;
          return ListTile(
            leading: CircleAvatar(child: Text(m.firstName[0])),
            title: Text(m.fullName),
            subtitle: Text(m.emailId),
          );
        },
      ),
    );
  }
}

// --- GENERIC CRUD ---
class GenericCRUD extends StatelessWidget {
  final String title, boxKey;

  const GenericCRUD({super.key, required this.title, required this.boxKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ValueListenableBuilder(
        valueListenable: DatabaseService.box(boxKey).listenable(),
        builder: (c, Box b, _) => ListView.builder(
          itemCount: b.length,
          itemBuilder: (c, i) {
            final item = b.getAt(i);
            String name = '';
            if (item is Category) name = item.categoryName;
            if (item is Publisher) name = item.publisherName;
            if (item is Location) name = item.shelfName;
            if (item is Author) name = item.fullName;

            return ListTile(
              title: Text(name),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => b.deleteAt(i),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _add(BuildContext context) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add $title'),
        content: TextField(controller: c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final b = DatabaseService.box(boxKey);
              if (boxKey == 'cat') {
                b.add(Category(categoryId: DatabaseService.nextId('cat', 'categoryId'), categoryName: c.text));
              }
              if (boxKey == 'pub') {
                b.add(Publisher(
                  publisherId: DatabaseService.nextId('pub', 'publisherId'),
                  publisherName: c.text,
                  publicationLanguage: 'English',
                  publicationType: 'General',
                ));
              }
              if (boxKey == 'loc') {
                b.add(Location(
                  locationId: DatabaseService.nextId('loc', 'locationId'),
                  shelfNo: 'A1',
                  shelfName: c.text,
                  floorNo: '1',
                ));
              }
              if (boxKey == 'auth') {
                b.add(Author(
                  authorId: DatabaseService.nextId('auth', 'authorId'),
                  firstName: c.text,
                  lastName: '',
                ));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// --- FORMS ---
class AddBook extends StatefulWidget {
  final Book? book;
  const AddBook({super.key, this.book});

  @override
  State<AddBook> createState() => _AddBookState();
}

class _AddBookState extends State<AddBook> {
  final _f = GlobalKey<FormState>();
  late TextEditingController tC, iC, eC, yC, cC;
  int? cat, pub, auth, loc;

  @override
  void initState() {
    super.initState();
    tC = TextEditingController(text: widget.book?.bookTitle);
    iC = TextEditingController(text: widget.book?.isbnCode);
    eC = TextEditingController(text: widget.book?.bookEdition ?? '1st');
    yC = TextEditingController(text: widget.book?.publicationYear.toString() ?? '2024');
    cC = TextEditingController(text: widget.book?.copiesTotal.toString() ?? '1');
    cat = widget.book?.categoryId;
    pub = widget.book?.publisherId;
    auth = widget.book?.authorId;
    loc = widget.book?.locationId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book == null ? 'Add Book' : 'Edit Book')),
      body: Form(
        key: _f,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _field('Book Title', tC, Icons.title),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _field('ISBN Code', iC, Icons.qr_code)),
                const SizedBox(width: 16),
                Expanded(child: _field('Edition', eC, Icons.edit)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _field('Year', yC, Icons.calendar_today, isNum: true)),
                const SizedBox(width: 16),
                Expanded(child: _field('Copies', cC, Icons.copy, isNum: true)),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Relationships', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: auth,
              decoration: _deco('Author', Icons.person),
              items: DatabaseService.box('auth').values.map((x) => DropdownMenuItem(value: (x as Author).authorId, child: Text(x.fullName))).toList(),
              onChanged: (v) => setState(() => auth = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: cat,
              decoration: _deco('Category', Icons.category),
              items: DatabaseService.box('cat').values.map((x) => DropdownMenuItem(value: (x as Category).categoryId, child: Text(x.categoryName))).toList(),
              onChanged: (v) => setState(() => cat = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: pub,
              decoration: _deco('Publisher', Icons.business),
              items: DatabaseService.box('pub').values.map((x) => DropdownMenuItem(value: (x as Publisher).publisherId, child: Text(x.publisherName))).toList(),
              onChanged: (v) => setState(() => pub = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: loc,
              decoration: _deco('Shelf Location', Icons.location_on),
              items: DatabaseService.box('loc').values.map((x) => DropdownMenuItem(value: (x as Location).locationId, child: Text('${x.shelfName} (${x.shelfNo})'))).toList(),
              onChanged: (v) => setState(() => loc = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _save,
              child: Text(widget.book == null ? 'Save Book' : 'Update Book', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String l, TextEditingController c, IconData i, {bool isNum = false}) => TextFormField(
    controller: c,
    keyboardType: isNum ? TextInputType.number : TextInputType.text,
    decoration: _deco(l, i),
    validator: (v) => v!.isEmpty ? 'Required' : null,
  );

  InputDecoration _deco(String l, IconData i) => InputDecoration(
    labelText: l,
    prefixIcon: Icon(i),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
    filled: true,
    fillColor: Colors.white,
  );

  void _save() {
    if (_f.currentState!.validate() && cat != null && pub != null && auth != null && loc != null) {
      if (widget.book == null) {
        DatabaseService.box('books').add(Book(
          bookId: DatabaseService.nextId('books', 'bookId'),
          isbnCode: iC.text,
          bookTitle: tC.text,
          categoryId: cat!,
          publisherId: pub!,
          authorId: auth!,
          publicationYear: int.tryParse(yC.text) ?? 2024,
          bookEdition: eC.text,
          copiesTotal: int.tryParse(cC.text) ?? 1,
          copiesAvailable: int.tryParse(cC.text) ?? 1,
          locationId: loc!,
        ));
      } else {
        widget.book!.bookTitle = tC.text;
        widget.book!.isbnCode = iC.text;
        widget.book!.categoryId = cat!;
        widget.book!.publisherId = pub!;
        widget.book!.authorId = auth!;
        widget.book!.publicationYear = int.tryParse(yC.text) ?? 2024;
        widget.book!.bookEdition = eC.text;
        widget.book!.copiesTotal = int.tryParse(cC.text) ?? 1;
        widget.book!.locationId = loc!;
        widget.book!.save();
      }
      Navigator.pop(context);
    }
  }
}

class AddMem extends StatelessWidget {
  const AddMem({super.key});

  @override
  Widget build(BuildContext context) {
    final fC = TextEditingController();
    final lC = TextEditingController();
    final eC = TextEditingController();
    final mC = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Member'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _field('First Name', fC, Icons.person),
          const SizedBox(height: 16),
          _field('Last Name', lC, Icons.person_outline),
          const SizedBox(height: 16),
          _field('Email Address', eC, Icons.email),
          const SizedBox(height: 16),
          _field('Mobile Number', mC, Icons.phone),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () {
              DatabaseService.box('mem').add(Member(
                memberId: DatabaseService.nextId('mem', 'memberId'),
                firstName: fC.text,
                lastName: lC.text,
                city: 'Default',
                mobileNo: mC.text,
                emailId: eC.text,
                dateOfBirth: '1990-01-01',
                activeStatusId: 1,
              ));
              Navigator.pop(context);
            },
            child: const Text('Register Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _field(String l, TextEditingController c, IconData i) => Padding(
    padding: const EdgeInsets.only(bottom: 0),
    child: TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: l,
        prefixIcon: Icon(i),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
  );
}
