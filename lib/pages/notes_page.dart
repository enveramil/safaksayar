import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class NotesScreen extends StatefulWidget {
  final BuildContext context;

  const NotesScreen({super.key, required this.context});
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late Database _database;
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'notes.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT, date DATETIME)",
        );
      },
      version: 1,
    );
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final List<Map<String, dynamic>> notes = await _database.query('notes');
    setState(() {
      _notes = notes;
    });
  }

  Future<void> _addOrUpdateNote({int? id, required String text}) async {
    final String date = DateTime.now().toIso8601String();
    if (id == null) {
      await _database.insert('notes', {'text': text, 'date': date});
    } else {
      await _database.update('notes', {'text': text, 'date': date},
          where: 'id = ?', whereArgs: [id]);
    }
    _loadNotes();
  }

  Future<void> _deleteNote(int id) async {
    await _database.delete('notes', where: 'id = ?', whereArgs: [id]);
    _loadNotes();
  }

  void _showNoteBottomSheet(
      {int? id, String? existingText, required BuildContext context}) {
    TextEditingController _controller =
        TextEditingController(text: existingText ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        double screenHeight = MediaQuery.of(context).size.height;
        double bottomSheetHeight = screenHeight * 0.8; // BottomSheet yüksekliği
        double textFieldMaxHeight =
            bottomSheetHeight - 100; // Başlık ve butonlar hariç kalan alan
        int maxLines =
            (textFieldMaxHeight / 24).floor(); // Ortalama satır yüksekliği 24px

        return FractionallySizedBox(
          widthFactor: 1,
          heightFactor: 0.8,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  id == null ? "Yeni Not Ekle" : "Notu Düzenle",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: maxLines.clamp(5, 25), // Min 5, Max 25
                    decoration: InputDecoration(
                      hintText: "Notunuzu buraya yazın...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (id != null)
                      Expanded(
                        child: Container(
                          height: 50,
                          margin: EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade300,
                                Colors.red.shade700
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () {
                              _deleteNote(id);
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                            ),
                            child: Text("Sil",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Container(
                        height: 50,
                        margin: EdgeInsets.only(left: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade700
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton(
                          onPressed: () {
                            if (_controller.text.isNotEmpty) {
                              _addOrUpdateNote(id: id, text: _controller.text);
                            }
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                          child: Text("Kaydet",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("Notlar"),
          surfaceTintColor: Colors.white,
          backgroundColor: Colors.white,
        ),
        body: ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: _notes.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 4, // Hafif gölge efekti
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12), // Köşeleri yuvarlak yapar
              ),
              child: ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  radius: 16,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  _notes[index]['text'],
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis),
                ),
                subtitle: Text(
                  DateFormat('yyyy-MM-dd HH:mm:ss')
                      .format(DateTime.parse(_notes[index]['date'])),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing:
                    Icon(Icons.edit, color: Colors.blue), // Düzenleme simgesi
                onTap: () => _showNoteBottomSheet(
                  id: _notes[index]['id'],
                  existingText: _notes[index]['text'],
                  context: context,
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showNoteBottomSheet(context: context),
          backgroundColor: Colors.green, // Renk seçimi
          elevation: 8.0, // Gölge efekti
          icon: Icon(
            Icons.add,
            color: Colors.white, // İkon rengi
          ),
          label: Text(
            'Not Ekle', // Metin ekleme
            style: TextStyle(
              color: Colors.white, // Metin rengi
              fontSize: 16.0, // Metin boyutu
              fontWeight: FontWeight.bold, // Metin kalınlığı
            ),
          ),
          shape: RoundedRectangleBorder(
            // Şekil değişikliği
            borderRadius: BorderRadius.circular(15.0), // Köşeleri yuvarlatma
          ),
          splashColor: Colors.pink, // Tıklama efekti
        ));
  }
}
