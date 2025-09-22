import 'dart:convert';
import 'package:http/http.dart' as http;
import 'main.dart'; // Task 모델을 가져오기 위함

class ApiService {
  // https://interior-sondra-kimilguk-app-99ae6359.koyeb.app/todolist 일때 int
  // https://shrimo.com/fake-api/todos 일때 id가 String이기 때문에 dynamic형으로 변경
  static const String _baseUrl = 'http://localhost:8888/todolist'; // 예시 URL

  Future<List<Task>> getTasks(description) async { //* description을 조회조건으로 사용
    if(description=='null')description='test'; //* test용 자료만
    print(description); //* 디버그
    try {
      final response = await http.get(Uri.parse('${_baseUrl}/?description=$description')); //*
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((model) => Task.fromJson(model)).toList().reversed.toList();//역순
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
    final newItem = { //주, 아래는 필수 값이고, 빠지면 신규 데이터가 입력이 되지 않는다.
      'title': task.title,
      'description': 'test',
      'dueDate': DateTime.now().toString(),//'2025-07-15',
      'priority': 'High',
      'status': task.status,
      'tags': ['test'],
    }; // API 요구사항에 따라 위 처럼 필드를 추가할 수 있습니다.
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(newItem), //task.toJson() 대신 API요구사항으로 필드추가처리
      );
      if (response.statusCode == 201) { // 201 Created
        //return Task.fromJson(json.decode(response.body));
        print(response.body);
        Map<String, dynamic> jsonResponse = json.decode(response.body);//['data'];
        /*
        // 키 변경이 필요하다.
        if (jsonResponse.containsKey('id')) {
          jsonResponse['_id'] = jsonResponse.remove('id');
        }
        */
        print(jsonResponse);
        return Task.fromJson(jsonResponse);
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
        //return Task.fromJson(json.decode(response.body));
        print(response.body);
        Map<String, dynamic> jsonResponse = json.decode(response.body);//['data'];
        /*
        // 키 변경이 필요하다.
        if (jsonResponse.containsKey('id')) {
          jsonResponse['_id'] = jsonResponse.remove('id');
        }
       */
        print(jsonResponse);
        return Task.fromJson(jsonResponse);
      } else {
        throw Exception(
            'Failed to update task (Status Code: ${response.statusCode})');
      }
    } catch (e) {
      print('Error updating task: $e');
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(dynamic taskId) async {
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