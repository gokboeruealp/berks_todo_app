import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_item.dart';

class DailyTodosScreen extends StatelessWidget {
  const DailyTodosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);
    final dailyTodos = todoProvider.dailyTodos;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlük Görevler'),
      ),
      body: Column(
        children: [
          Expanded(
            child: dailyTodos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.replay_circle_filled,
                          size: 80,
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz günlük görev eklenmemiş',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _addDailyTodoDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Günlük Görev Ekle'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: dailyTodos.length,
                    itemBuilder: (context, index) {
                      return TodoItem(
                        todo: dailyTodos[index],
                        onToggle: () {
                          todoProvider.toggleTodoStatus(dailyTodos[index]);
                        },
                        onDelete: () {
                          todoProvider.deleteTodo(dailyTodos[index].id!);
                        },
                        onEdit: () {
                          _editTodoDialog(context, dailyTodos[index]);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDailyTodoDialog(context),
        tooltip: 'Günlük görev ekle',
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _addDailyTodoDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Günlük Görev Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    labelText: 'Saat (Ör: 14:30)',
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onTap: () async {
                    // Hide keyboard
                    FocusScope.of(context).requestFocus(FocusNode());
                    
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            timePickerTheme: TimePickerTheme.of(context).copyWith(
                              backgroundColor: theme.colorScheme.surface,
                            ),
                          ),
                          child: child!,
                        );
                      }
                    );
                    
                    if (picked != null) {
                      timeController.text = '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'İptal',
                style: TextStyle(color: theme.colorScheme.secondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && descController.text.isNotEmpty) {
                  Provider.of<TodoProvider>(context, listen: false).addTodo(
                    Todo(
                      title: titleController.text,
                      description: descController.text,
                      time: timeController.text.isEmpty ? null : timeController.text,
                      type: TodoType.daily,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  void _editTodoDialog(BuildContext context, Todo todo) {
    final TextEditingController titleController = TextEditingController(text: todo.title);
    final TextEditingController descController = TextEditingController(text: todo.description);
    final TextEditingController timeController = TextEditingController(text: todo.time ?? '');
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Günlük Görevi Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    labelText: 'Saat (Ör: 14:30)',
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onTap: () async {
                    // Hide keyboard
                    FocusScope.of(context).requestFocus(FocusNode());
                    
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            timePickerTheme: TimePickerTheme.of(context).copyWith(
                              backgroundColor: theme.colorScheme.surface,
                            ),
                          ),
                          child: child!,
                        );
                      }
                    );
                    
                    if (picked != null) {
                      timeController.text = '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'İptal',
                style: TextStyle(color: theme.colorScheme.secondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && descController.text.isNotEmpty) {
                  Provider.of<TodoProvider>(context, listen: false).updateTodo(
                    todo.copyWith(
                      title: titleController.text,
                      description: descController.text,
                      time: timeController.text.isEmpty ? null : timeController.text,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }
}