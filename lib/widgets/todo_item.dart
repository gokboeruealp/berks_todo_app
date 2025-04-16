import 'package:flutter/material.dart';
import '../models/todo.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isCheckVisible;

  const TodoItem({
    super.key,
    required this.todo,
    required this.onToggle,
    this.onDelete,
    this.onEdit,
    this.isCheckVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ExpansionTile(
          title: Text(
            todo.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: todo.isDone ? TextDecoration.lineThrough : null,
              color: todo.isDone ? theme.colorScheme.outline : theme.colorScheme.onSurface,
            ),
          ),
          subtitle: todo.time != null
              ? Text(
                  '⏰ ${todo.time}',
                  style: TextStyle(
                    color: todo.isDone ? theme.colorScheme.outline : theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : null,
          leading: isCheckVisible ? IconButton(
            icon: Icon(
              todo.isDone ? Icons.check_circle : Icons.circle_outlined,
              color: todo.isDone ? theme.colorScheme.primary : null,
              size: 28,
            ),
            onPressed: onToggle,
          ) : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null)
                IconButton(
                  icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                  onPressed: onEdit,
                ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete, color: theme.colorScheme.error),
                  onPressed: () => _showDeleteConfirmationDialog(context),
                ),
            ],
          ),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                todo.description,
                style: TextStyle(
                  color: todo.isDone ? theme.colorScheme.outline : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (todo.weekday != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Chip(
                    label: Text(
                      '${todo.weekday?.substring(0, 1).toUpperCase()}${todo.weekday?.substring(1)}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Görevi Sil'),
          content: const Text('Bu görevi silmek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete!();
              },
              child: Text(
                'Sil',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }
}