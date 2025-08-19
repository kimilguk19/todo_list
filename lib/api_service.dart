import 'dart:convert';
import 'package:http/http.dart' as http;
import 'main.dart'; // Task 모델을 가져오기 위함

class ApiService {
  // 실제 API의 기본 URL로 변경하세요.
  static const String _baseUrl = 'https://shrimo.com/fake-api/todos'; // 예시 URL

  Future<List<Task>> getTasks() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((model) => Task.fromJson(model)).toList();
      } else {
        throw Exception(
            'Failed to load tasks (Status Code: ${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      throw Exception('Failed to load tasks: $e');
    }
  }

  Future<Task> addTask(Task task) async {

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(task.toJson()),
      );
      if (response.statusCode == 201) { // 201 Created
        return Task.fromJson(json.decode(response.body));
      } else {
        throw Exception(
            'Failed to add task (Status Code: ${response.statusCode})');
      }
    } catch (e) {
      print('Error adding task: $e');
      throw Exception('Failed to add task: $e');
    }
  }

  Future<Task> updateTask(Task task) async {
    if (task.id == null) {
      throw Exception('Task ID cannot be null for update');
    }
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/${task.id}'), // ID를 URL에 포함
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(task.toJson()),
      );
      if (response.statusCode == 200) {
        return Task.fromJson(json.decode(response.body));
      } else {
        throw Exception(
            'Failed to update task (Status Code: ${response.statusCode})');
      }
    } catch (e) {
      print('Error updating task: $e');
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$taskId'), // ID를 URL에 포함
      );
      if (response.statusCode != 200 &&
          response.statusCode != 204) { // 204 No Content
        throw Exception(
            'Failed to delete task (Status Code: ${response.statusCode})');
      }
    } catch (e) {
      print('Error deleting task: $e');
      throw Exception('Failed to delete task: $e');
    }
  }
}