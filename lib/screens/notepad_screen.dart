import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../services/local_storage_service.dart';
import '../models/note.dart';

class NotepadScreen extends StatefulWidget {
  const NotepadScreen({super.key});

  @override
  State<NotepadScreen> createState() => _NotepadScreenState();
}

class _NotepadScreenState extends State<NotepadScreen> {
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final storage = await LocalStorageService.getInstance();
    final notesData = await storage.getNotes();
    setState(() {
      _notes = notesData.map((n) => Note.fromJson(n)).toList();
      _isLoading = false;
    });
  }

  Future<void> _createNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _NoteEditorScreen()),
    );
    if (result == true) await _loadNotes();
  }

  Future<void> _editNote(Note note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _NoteEditorScreen(note: note)),
    );
    if (result == true) await _loadNotes();
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Delete "${note.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final storage = await LocalStorageService.getInstance();
      await storage.deleteNote(note.id!);
      await _loadNotes();
    }
  }

  Uint8List? _getDrawingImage(String? drawingData) {
    if (drawingData == null || drawingData.isEmpty) return null;
    try {
      return base64Decode(drawingData);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notepad'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNote,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note, size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No notes yet',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createNote,
              icon: const Icon(Icons.add),
              label: const Text('Create Note'),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          final hasDrawing = note.drawingData != null && note.drawingData!.isNotEmpty;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.edit_note, color: isDark ? Colors.amber[300] : Colors.amber),
                  ),
                  title: Text(
                    note.title.isNotEmpty ? note.title : 'Untitled',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    note.content.isNotEmpty ? note.content : 'No content',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  trailing: PopupMenuButton(
                    onSelected: (value) {
                      if (value == 'edit') _editNote(note);
                      if (value == 'delete') _deleteNote(note);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                  onTap: () => _editNote(note),
                ),
                if (hasDrawing)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _getDrawingImage(note.drawingData)!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const _NoteEditorScreen({this.note});

  @override
  State<_NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<_NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late SignatureController _signatureController;
  bool _isDrawing = false;
  Uint8List? _savedDrawing;

  @override
  void initState() {
    super.initState();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pen color adapts to theme: white for dark mode, black for light mode
    _signatureController = SignatureController(
      penStrokeWidth: 2,
      penColor: isDark ? Colors.white : Colors.black,
      exportBackgroundColor: isDark ? Colors.grey[900] : Colors.white,
    );

    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      if (widget.note!.drawingData != null && widget.note!.drawingData!.isNotEmpty) {
        _savedDrawing = base64Decode(widget.note!.drawingData!);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update pen color when theme changes
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _signatureController.penColor = isDark ? Colors.white : Colors.black;
    _signatureController.exportBackgroundColor = isDark ? Colors.grey[900] : Colors.white;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final storage = await LocalStorageService.getInstance();

    String? drawingData;
    if (_isDrawing && _signatureController.isNotEmpty) {
      final exportData = await _signatureController.toPngBytes();
      if (exportData != null) {
        drawingData = base64Encode(exportData);
      }
    } else if (_savedDrawing != null) {
      drawingData = base64Encode(_savedDrawing!);
    }

    final noteData = {
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'drawing_data': drawingData,
    };

    if (widget.note != null) {
      await storage.updateNote(widget.note!.id!, noteData);
    } else {
      await storage.insertNote(noteData);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _clearDrawing() {
    _signatureController.clear();
    setState(() {
      _savedDrawing = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Content',
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                alignLabelWithHint: true,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.white,
              ),
              maxLines: 10,
            ),
            const SizedBox(height: 16),

            if (_savedDrawing != null && !_isDrawing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved Drawing',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _savedDrawing!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            Row(
              children: [
                Icon(Icons.edit, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                const SizedBox(width: 8),
                Text(
                  'Drawing Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _isDrawing,
                  onChanged: (value) {
                    setState(() {
                      _isDrawing = value;
                      if (!value && _savedDrawing == null) {
                        _clearDrawing();
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isDrawing) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? Colors.grey[900] : Colors.white,
                ),
                child: Signature(
                  controller: _signatureController,
                  width: double.infinity,
                  height: 200,
                  backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _clearDrawing,
                    icon: const Icon(Icons.clear),
                    label: Text('Clear Drawing', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: isDark ? Colors.white70 : Colors.black54),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Draw with your finger. Pen color: ${isDark ? "White" : "Black"}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}