import 'package:flutter/material.dart';
import 'api_service.dart'; // ApiService 임포트
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
// 카카오로그인 취소로 뒤로가기 기능이 필요할 때 예외처리 사용(아래)
import 'package:flutter/services.dart' show PlatformException;

void main() async {
  // 웹 환경에서 카카오 로그인을 정상적으로 완료하려면 runApp() 호출 전 아래 메서드 호출 필요
  WidgetsFlutterBinding.ensureInitialized();

  // 여기에 카카오 SDK 초기화 코드를 추가합니다.
  // 앱 실행 전 SDK 초기화 Flutter.onErrorBinding 핸들러는 KakaoSdk.init() 내부에서 초기화합니다.
  // KakaoSdk.init()으로 초기화 되어야 하는 플러그인을 사용할 경우 명시적으로 초기화하지 않아도 사용 가능합니다.
  try {
    KakaoSdk.init(
      nativeAppKey: 'YOUR_NATIVE_APP_KEY', // 네이티브 앱 키 (Android/iOS 용) - 웹에서는 사용되지 않을 수 있음
      javaScriptAppKey: '58e3e66717008e67f47f0b53356b63a7', // 카카오 개발자 콘솔의 JavaScript 키
    );
    print('Kakao SDK initialized successfully');
  } catch (e) {
    print('Failed to initialize Kakao SDK: $e');
  }

  runApp(MyApp());
}

  class Task { //* 회원조회에 사용할 description 필드 추가예정.
  // https://interior-sondra-kimilguk-app-99ae6359.koyeb.app/todolist 일때 int
  // https://shrimo.com/fake-api/todos 일때 id가 String이기 때문에 dynamic형으로 변경
  dynamic id; // API에서 사용하는 ID (Nullable로 변경 또는 기본값 설정)
  String title;
  String status;

  Task({this.id, required this.title, this.status = 'Not Started'});

  // API 응답(JSON)을 Task 객체로 변환하는 factory 생성자
  factory Task.fromJson(Map<String, dynamic> json) {
  return Task(
  id: json['id'] as dynamic, // API 필드명에 맞게 수정 json['_id']
  title: json['title'] as String,
  status: json['status'] as String? ?? 'Not Started', // API 필드명 및 기본값 설정
  );
  }

  // Task 객체를 JSON으로 변환하는 메서드 (POST, PUT 요청 시 사용)
  Map<String, dynamic> toJson() {
    return {
      'id': id, // '_id':id는 서버에서 생성될 경우 보내지 않을 수 있음
      'title': title,
      'status': status,
    };
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
  List<Task> _tasks = []; // API에서 받아온 데이터를 저장할 리스트
  final TextEditingController _taskController = TextEditingController();
  final ApiService _apiService = ApiService(); // ApiService 인스턴스 생성
  bool _isLoading = true; // 로딩 상태
  String? _errorMessage; // 오류 메시지

  User? _loggedInUser; //* 카카오 사용자 정보
  // 카카오 로그인 시도 함수
  Future<void> _signInWithKakao() async {
    // 카카오톡 실행 가능 여부 확인
    // 카카오톡 실행이 가능하면 카카오톡으로 로그인, 아니면 카카오계정으로 로그인
    if (await isKakaoTalkInstalled()) {
      try {
        await UserApi.instance.loginWithKakaoTalk();
        print('카카오톡으로 로그인 성공');
        _getUserInfo(); // 로그인 성공 후 사용자 정보 가져오기
      } catch (error) {
        print('카카오톡으로 로그인 실패 $error');

        // 사용자가 카카오톡 설치 후 디바이스 권한 요청 화면에서 로그인을 취소한 경우,
        // 의도적인 로그인 취소로 보고 카카오계정으로 로그인 시도 없이 로그인 취소로 처리 (예: 뒤로 가기)
        if (error is PlatformException && error.code == 'CANCELED') {
          return;
        }
        // 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인
        try {
          await UserApi.instance.loginWithKakaoAccount();
          print('카카오계정으로 로그인 성공');
          _getUserInfo();
        } catch (error) {
          print('카카오계정으로 로그인 실패 $error');
          // 로그인 실패 처리 (예: 스낵바 메시지)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('카카오 로그인에 실패했습니다: $error')),
          );
        }
      }
    } else {
      try {
        await UserApi.instance.loginWithKakaoAccount();
        print('카카오계정으로 로그인 성공');
        _getUserInfo();
      } catch (error) {
        print('카카오계정으로 로그인 실패 $error');
        // 로그인 실패 처리
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카카오 로그인에 실패했습니다: $error')),
        );
      }
    }
  }

// 사용자 정보 가져오기 함수
  Future<void> _getUserInfo() async {
    try {
      User user = await UserApi.instance.me();
      print('사용자 정보 요청 성공'
          '\n회원번호: ${user.id}'
          '\n닉네임: ${user.kakaoAccount?.profile?.nickname}'
          '\n이메일: ${user.kakaoAccount?.email}');
      //* TODO: 가져온 사용자 정보를 앱 상태에 저장하거나 화면에 표시
      setState(() { _loggedInUser = user; });
      _fetchTasks(); //* 사용자 정보 요청 후 할 일 목록을 가져옵니다.
      // 예: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TodoListScreen(user: user)));
    } catch (error) {
      print('사용자 정보 요청 실패 $error');
    }
  }

// 로그아웃 함수 (선택 사항)
  Future<void> _signOutFromKakao() async {
    try {
      await UserApi.instance.logout();
      print('카카오 로그아웃 성공');
      //* TODO: 로그아웃 후 처리 (예: 로그인 화면으로 이동)
      setState(() { _loggedInUser = null; });
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TodoListScreen())); //* 화면새로고침
    } catch (error) {
      print('카카오 로그아웃 실패 $error');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTasks(); // 화면이 처음 로드될 때 할 일 목록을 가져옵니다.
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    print('여기 ${_loggedInUser?.id}');
    try {
      final tasks = await _apiService.getTasks((_loggedInUser?.id).toString()); //* DB조회조건 추가
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      // 사용자에게 오류를 알리는 스낵바 등을 표시할 수 있습니다.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('할 일 목록을 불러오는데 실패했습니다: $_errorMessage')),
      );
    }
  }

  Future<void> _addTask(String title) async {
    if (title.isNotEmpty) {
      final newTask = Task(title: title); // ID는 서버에서 생성될 것으로 가정
      try {
        final addedTask = await _apiService.addTask(newTask);
        setState(() {
          //_tasks.add(addedTask); // 서버로부터 받은 Task 객체 (ID 포함)를 추가
          _tasks.insert(0, addedTask); // 리스트의 맨 앞에 추가
        });
        _taskController.clear();
        Navigator.of(context).pop(); // 다이얼로그 닫기
      } catch (e) {
        // 오류 처리
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('할 일 추가에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _editTask(int index, String newTitle) async {
    if (newTitle.isNotEmpty) {
      Task taskToUpdate = _tasks[index];
      Task updatedTaskData = Task(id: taskToUpdate.id, title: newTitle, status: taskToUpdate.status);
      try {
        final updatedTask = await _apiService.updateTask(updatedTaskData);
        setState(() {
          _tasks[index] = updatedTask;
        });
        Navigator.of(context).pop(); // 다이얼로그 닫기
      } catch (e) {
        // 오류 처리
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('할 일 수정에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask(int index) async {
    final dynamic taskId = _tasks[index].id;
    if (taskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제할 태스크의 ID가 없습니다.')),
      );
      return;
    }
    try {
      await _apiService.deleteTask(taskId);
      setState(() {
        _tasks.removeAt(index);
      });
    } catch (e) {
      // 오류 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('할 일 삭제에 실패했습니다: $e')),
      );
    }
  }

  Future<void> _toggleTaskStatus(int index) async {
    Task taskToToggle = _tasks[index];
    Task updatedTaskData = Task(
        id: taskToToggle.id,
        title: taskToToggle.title,
        status: taskToToggle.status=='Not Started'?'Started':'Not Started');
    try {
      final updatedTask = await _apiService.updateTask(updatedTaskData);
      setState(() {
        _tasks[index] = updatedTask;
      });
    } catch (e) {
      // 오류 처리
      // 원래 상태로 되돌릴 수도 있습니다.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상태 변경에 실패했습니다: $e')),
      );
    }
  }

  // _showAddTaskDialog, _submitTaskDialog, _showEditTaskDialog, _submitEditTaskDialog 메서드는
  // 비동기 작업 (_addTask, _editTask)을 호출하도록 수정합니다.
  // 예를 들어 _submitTaskDialog:
  void _submitTaskDialog() {
    // await를 사용하지 않고 _addTask를 호출합니다. _addTask 내부에서 Navigator.pop()을 처리합니다.
    _addTask(_taskController.text);
    // Navigator.of(context).pop(); // _addTask 또는 _editTask 내부로 이동
  }

  void _submitEditTaskDialog(int index) {
    _editTask(index, _taskController.text);
    // Navigator.of(context).pop(); // _addTask 또는 _editTask 내부로 이동
  }


  // _showAddTaskDialog 메서드 수정 (onSubmitted에서 _submitTaskDialog 호출)
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
            onSubmitted: (_) => _submitTaskDialog(), // 변경 없음
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
              onPressed: _submitTaskDialog, // 변경 없음
            ),
          ],
        );
      },
    );
  }

  // _showEditTaskDialog 메서드 수정 (onSubmitted에서 _submitEditTaskDialog 호출)
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
            onSubmitted: (_) => _submitEditTaskDialog(index), // 변경 없음
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
              onPressed: () => _submitEditTaskDialog(index), // 변경 없음
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('오늘의 할 일 (API 연동)'),
        backgroundColor: Colors.lightBlueAccent, // 여름 색상으로 변경 (예: 하늘색)
        actions: [ // 새로고침 버튼 추가 (선택 사항)
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchTasks,
          ),
          (_loggedInUser != null)
          ?Text('안녕 ${_loggedInUser!.id} 님'):Text('로그인 하세요'),
          (_loggedInUser != null)
          ?IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOutFromKakao, //* 로그아웃 버튼에 함수 연결
            tooltip: '카카오 로그아웃',
          )
          :IconButton(
            icon: Icon(Icons.login),
            onPressed: _signInWithKakao, //* 로그인 버튼에 함수 연결
            tooltip: '카카오 로그인',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('오류 발생: $_errorMessage', textAlign: TextAlign.center),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchTasks,
              child: Text('다시 시도'),
            )
          ],
        ),
      )
          : _tasks.isEmpty
          ? Center(child: Text('할 일이 없습니다. 추가해보세요!'))
          : ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          // 인덱스에 따라 배경색 결정
          final itemBackgroundColor = index.isEven
              ? Colors.grey[200]  // 짝수 항목 배경색
              : Colors.white;     // 홀수 항목 배경색
          return Container(
            decoration: BoxDecoration(
              color: itemBackgroundColor,
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: ListTile(
              leading: Checkbox(
                value: task.status == 'Started'?true:false,
                onChanged: (_) => _toggleTaskStatus(index),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.status=='Started'
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
            ),
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