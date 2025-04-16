import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_item.dart';
import '../widgets/time_picker_widget.dart';

class TodaySpecificTodosScreen extends StatelessWidget {
  const TodaySpecificTodosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);
    final todaySpecificTodos = todoProvider.todaySpecificTodos;
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bugüne Özel Görevler')
      ),
      body: Column(
        children: [
          Expanded(
            child: todaySpecificTodos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.today,
                          size: 80,
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bugüne özel görev eklenmemiş',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _addTodaySpecificTodoDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Görev Ekle'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: todaySpecificTodos.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TodoItem(
                          todo: todaySpecificTodos[index],
                          onToggle: () {
                            todoProvider.toggleTodoStatus(todaySpecificTodos[index]);
                          },
                          onDelete: () {
                            todoProvider.deleteTodo(todaySpecificTodos[index].id!);
                          },
                          onEdit: () {
                            _editTodoDialog(context, todaySpecificTodos[index]);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTodaySpecificTodoDialog(context),
        tooltip: 'Bugüne özel görev ekle',
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _addTodaySpecificTodoDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bugüne Özel Görev Ekle'),
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
                  readOnly: true,
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
                    
                    final String? pickedTime = await showCustomTimePicker(
                      context,
                      initialTime: timeController.text,
                    );
                    
                    if (pickedTime != null) {
                      timeController.text = pickedTime;
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
                style: TextStyle(color: theme.colorScheme.error),
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
                      type: TodoType.today,
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
          title: const Text('Bugüne Özel Görevi Düzenle'),
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
                  readOnly: true,
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
                    
                    final String? pickedTime = await showCustomTimePicker(
                      context,
                      initialTime: timeController.text,
                    );
                    
                    if (pickedTime != null) {
                      timeController.text = pickedTime;
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
                style: TextStyle(color: theme.colorScheme.error),
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