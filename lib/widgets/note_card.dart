import 'package:flutter/material.dart';
import '../models/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity( 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.edit_note, color: Colors.amber),
        ),
        title: Text(
          note.title.isNotEmpty ? note.title : 'Untitled',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          note.content.isNotEmpty ? note.content : 'No content',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}
