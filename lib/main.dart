import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class Task {
  String title;
  bool isDone;

  Task({required this.title, this.isDone = false});
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '오늘의 할 일',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<Task> _tasks = [];
  final TextEditingController _taskController = TextEditingController();

  void _addTask(String title) {
    if (title.isNotEmpty) {
      setState(() {
        _tasks.add(Task(title: title));
      });
      _taskController.clear();
    }
  }

  void _editTask(int index, String newTitle) {
    if (newTitle.isNotEmpty) {
      setState(() {
        _tasks[index].title = newTitle;
      });
    }
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  void _toggleTaskStatus(int index) {
    setState(() {
      _tasks[index].isDone = !_tasks[index].isDone;
    });
  }

  void _showAddTaskDialog() {
    _taskController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('새 할 일 추가'),
          content: TextField(
            controller: _taskController,
            autofocus: true,
            decoration: InputDecoration(hintText: '할 일을 입력하세요'),
            onSubmitted: (_) => _submitTaskDialog(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('추가'),
              onPressed: _submitTaskDialog,
            ),
          ],
        );
      },
    );
  }

  void _submitTaskDialog() {
    _addTask(_taskController.text);
    Navigator.of(context).pop();
  }

  void _showEditTaskDialog(int index) {
    _taskController.text = _tasks[index].title;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('할 일 수정'),
          content: TextField(
            controller: _taskController,
            autofocus: true,
            decoration: InputDecoration(hintText: '새 할 일을 입력하세요'),
            onSubmitted: (_) => _submitEditTaskDialog(index),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('저장'),
              onPressed: () => _submitEditTaskDialog(index),
            ),
          ],
        );
      },
    );
  }

  void _submitEditTaskDialog(int index) {
    _editTask(index, _taskController.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('오늘의 할 일'),
      ),
      body: _tasks.isEmpty
          ? Center(child: Text('할 일이 없습니다. 추가해보세요!'))
          : ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return ListTile(
            leading: Checkbox(
              value: task.isDone,
              onChanged: (_) => _toggleTaskStatus(index),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.isDone
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _showEditTaskDialog(index),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteTask(index),
                ),
              ],
            ),
            onTap: () => _toggleTaskStatus(index),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        tooltip: '할 일 추가',
        child: Icon(Icons.add),
      ),
    );
  }
}