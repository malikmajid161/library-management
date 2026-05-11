import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/library_models.dart';
import 'theme/app_theme.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _editionController = TextEditingController(text: '1st');
  int? _selectedCategory;
  int? _selectedPublisher;

  @override
  Widget build(BuildContext context) {
    final categories = Hive.box('categories').values.cast<Category>().toList();
    final publishers = Hive.box('publishers').values.cast<Publisher>().toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Book')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildField('Book Title', _titleController, Icons.title),
            const SizedBox(height: 16),
            _buildField('ISBN Code', _isbnController, Icons.qr_code),
            const SizedBox(height: 16),
            _buildField('Edition', _editionController, Icons.edit),
            const SizedBox(height: 24),
            
            const Text('Relationships', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            
            DropdownButtonFormField<int>(
              decoration: _inputDecoration('Category', Icons.category),
              value: _selectedCategory,
              items: categories.map((c) => DropdownMenuItem(value: c.categoryId, child: Text(c.categoryName))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Please select a category' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: _inputDecoration('Publisher', Icons.business),
              value: _selectedPublisher,
              items: publishers.map((p) => DropdownMenuItem(value: p.publisherId, child: Text(p.publisherName))).toList(),
              onChanged: (v) => setState(() => _selectedPublisher = v),
              validator: (v) => v == null ? 'Please select a publisher' : null,
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
              child: const Text('Save Book', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
      validator: (v) => v!.isEmpty ? 'Required field' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box('books');
      final id = box.isEmpty ? 1 : (box.values.cast<Book>().last.bookId + 1);
      
      box.add(Book(
        bookId: id,
        isbnCode: _isbnController.text,
        bookTitle: _titleController.text,
        categoryId: _selectedCategory!,
        publisherId: _selectedPublisher!,
        publicationYear: 2024,
        bookEdition: _editionController.text,
        copiesTotal: 1,
        copiesAvailable: 1,
        locationId: 1,
      ));
      
      Navigator.pop(context);
    }
  }
}
