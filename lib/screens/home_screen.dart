import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import '../widgets/todo_item.dart';
import '../widgets/time_picker_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);
    final todayTodos = todoProvider.todayTodos;
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bugün'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsDialog(context, todoProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: todayTodos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bugün için hiç görev yok!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _addTodoDialog(context, TodoType.today),
                          icon: const Icon(Icons.add),
                          label: const Text('Görev Ekle'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: todayTodos.length,
                    itemBuilder: (context, index) {
                      return TodoItem(
                        todo: todayTodos[index],
                        isCheckVisible: true,
                        onToggle: () {
                          todoProvider.toggleTodoStatus(todayTodos[index]);
                        },
                        onDelete: () {
                          todoProvider.deleteTodo(todayTodos[index].id!);
                        },
                        onEdit: () {
                          _editTodoDialog(context, todayTodos[index]);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTodoDialog(context, TodoType.today),
        tooltip: 'Bugüne görev ekle',
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, TodoProvider todoProvider) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ayarlar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('CSV olarak dışa aktar'),
              onTap: () async {
                Navigator.pop(dialogContext);
                await _showExportDialog(context, todoProvider);
              },
            ),
            Divider(color: theme.dividerColor),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('CSV\'den içe aktar'),
              onTap: () async {
                Navigator.pop(dialogContext);
                await _importFromCsv(context, todoProvider);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Kapat',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  // Yeni metot: CSV dışa aktarma için dosya adı soracak dialog
  Future<void> _showExportDialog(BuildContext context, TodoProvider todoProvider) async {
    final TextEditingController fileNameController = TextEditingController(text: 'todos.csv');
    final theme = Theme.of(context);
    
    // Show dialog to get file name
    final bool? shouldExport = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('CSV Olarak Dışa Aktar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Dışa aktarılacak dosya adını belirtin:',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: fileNameController,
              decoration: InputDecoration(
                labelText: 'Dosya Adı',
                hintText: 'todos.csv',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Not: Önce bir klasör seçmeniz istenecek, ardından bu dosya adı ile CSV dosyanız oluşturulacaktır.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'İptal',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Dosya Adını Onayla'),
          ),
        ],
      ),
    );

    if (shouldExport == true) {
      // Ensure the file name is not empty and has .csv extension
      String fileName = fileNameController.text.trim();
      
      if (fileName.isEmpty) {
        fileName = 'todos.csv';
      } else if (!fileName.toLowerCase().endsWith('.csv')) {
        fileName = '$fileName.csv';
      }
      
      await _exportToCsv(context, todoProvider, fileName);
    }
  }

  Future<void> _exportToCsv(
    BuildContext context, 
    TodoProvider todoProvider, 
    [String fileName = 'todos.csv']
  ) async {
    // Store a reference to the scaffold messenger
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final filePath = await todoProvider.exportToCsv(defaultFileName: fileName);
      
      if (filePath != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('CSV dosyası başarıyla dışa aktarıldı:\n$filePath'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Tamam',
              onPressed: () {},
            ),
          ),
        );
      } else {
        // Kullanıcı dosya veya klasör seçimini iptal etmiş olabilir
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Dışa aktarma iptal edildi'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog(context, 'Dışa aktarma hatası: $e');
    }
  }

  Future<void> _importFromCsv(BuildContext context, TodoProvider todoProvider) async {
    // Store a reference to the scaffold messenger
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    BuildContext? loadingDialogContext;
    
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('CSV\'den İçe Aktar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CSV dosyasından görevleri içe aktarmak istiyor musunuz?\n',
              ),
              const Text(
                'Dosya seçim penceresi açılacak ve bir CSV dosyası seçmeniz gerekecektir.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Not: İçe aktarılan görevler mevcut görevlere eklenecektir.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('İçe Aktar'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Show loading indicator (will be shown after file selection)
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            loadingDialogContext = dialogContext;
            return const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('CSV dosyasından içe aktarılıyor...'),
                ],
              ),
            );
          },
        );

        final importedCount = await todoProvider.importFromCsv();
        
        // Close loading dialog if it's still showing and context is valid
        if (loadingDialogContext != null && Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        
        if (importedCount > 0) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('$importedCount görev başarıyla içe aktarıldı'),
              action: SnackBarAction(
                label: 'Tamam',
                onPressed: () {},
              ),
            ),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('İçe aktarılan görev bulunamadı veya işlem iptal edildi'),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if it's still showing and context is valid
      if (loadingDialogContext != null && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showErrorDialog(context, 'İçe aktarma hatası: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    // Use a check to ensure the context is valid before showing the dialog
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Hata'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }

  void _addTodoDialog(BuildContext context, TodoType type) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bugüne Görev Ekle'),
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
                style: TextStyle(color: theme.colorScheme.primary),
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
                      type: type,
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
          title: const Text('Görevi Düzenle'),
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
                style: TextStyle(color: theme.colorScheme.primary),
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