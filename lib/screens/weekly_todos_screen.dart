import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_item.dart';

class WeeklyTodosScreen extends StatefulWidget {
  const WeeklyTodosScreen({super.key});

  @override
  State<WeeklyTodosScreen> createState() => _WeeklyTodosScreenState();
}

class _WeeklyTodosScreenState extends State<WeeklyTodosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);

    // Ensure tab and page are synced
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);
    final weekdays = todoProvider.getAllWeekdays();
    final currentIndex = 0;
    if (currentIndex >= 0 && _tabController.index != currentIndex) {
      _tabController.animateTo(currentIndex);
      _pageController.animateToPage(
        currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Haftalık Görevler'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          physics: const BouncingScrollPhysics(),
          tabAlignment: TabAlignment.start,
          tabs: weekdays.map((day) {
            return Tab(
              text: day.substring(0, 1).toUpperCase() + day.substring(1),
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                _tabController.animateTo(index);
              },
              children: weekdays.map((day) {
                return WeekDayTodoTab(weekday: day);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class WeekDayTodoTab extends StatelessWidget {
  final String weekday;

  const WeekDayTodoTab({
    super.key,
    required this.weekday,
  });

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);
    final weeklyTodosForDay = todoProvider.getWeeklyTodosByDay(weekday);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: weeklyTodosForDay.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 80,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${weekday.substring(0, 1).toUpperCase()}${weekday.substring(1)} için henüz görev eklenmemiş',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () =>
                              _addWeeklyTodoDialog(context, weekday),
                          icon: const Icon(Icons.add),
                          label: const Text('Görev Ekle'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: weeklyTodosForDay.length,
                    itemBuilder: (context, index) {
                      return TodoItem(
                        todo: weeklyTodosForDay[index],
                        onToggle: () {
                          todoProvider
                              .toggleTodoStatus(weeklyTodosForDay[index]);
                        },
                        onDelete: () {
                          todoProvider.deleteTodo(weeklyTodosForDay[index].id!);
                        },
                        onEdit: () {
                          _editTodoDialog(context, weeklyTodosForDay[index]);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addWeeklyTodoDialog(context, weekday),
        tooltip: 'Haftalık görev ekle',
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _addWeeklyTodoDialog(BuildContext context, String weekday) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
              '${weekday.substring(0, 1).toUpperCase()}${weekday.substring(1)} Görevi Ekle'),
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
                              timePickerTheme:
                                  TimePickerTheme.of(context).copyWith(
                                backgroundColor: theme.colorScheme.surface,
                              ),
                            ),
                            child: child!,
                          );
                        });

                    if (picked != null) {
                      timeController.text =
                          '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
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
                style: TextStyle(color: theme.colorScheme.tertiary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    descController.text.isNotEmpty) {
                  Provider.of<TodoProvider>(context, listen: false).addTodo(
                    Todo(
                      title: titleController.text,
                      description: descController.text,
                      time: timeController.text.isEmpty
                          ? null
                          : timeController.text,
                      weekday: weekday,
                      type: TodoType.weekly,
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
    final TextEditingController titleController =
        TextEditingController(text: todo.title);
    final TextEditingController descController =
        TextEditingController(text: todo.description);
    final TextEditingController timeController =
        TextEditingController(text: todo.time ?? '');
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Haftalık Görevi Düzenle'),
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
                              timePickerTheme:
                                  TimePickerTheme.of(context).copyWith(
                                backgroundColor: theme.colorScheme.surface,
                              ),
                            ),
                            child: child!,
                          );
                        });

                    if (picked != null) {
                      timeController.text =
                          '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
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
                style: TextStyle(color: theme.colorScheme.tertiary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    descController.text.isNotEmpty) {
                  Provider.of<TodoProvider>(context, listen: false).updateTodo(
                    todo.copyWith(
                      title: titleController.text,
                      description: descController.text,
                      time: timeController.text.isEmpty
                          ? null
                          : timeController.text,
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
