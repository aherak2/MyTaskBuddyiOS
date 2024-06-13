import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import '../components/CustomBottomNavigationBar.dart';
import '../components/TaskCard.dart';
import '../components/background_service.dart';
import '../screens/EditProfile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('bs');
  await _HomePageState().listenForNotifications();
  runApp(HomePage());
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late String firstname, lastname;
  void refreshTasks() {
    _getTasks();
  }

  List<Map<String, dynamic>> _tasks = [];
  int _selectedIndex = 0;
  DateTime _selectedDate = DateTime.now();
  int _selectedButtonIndex = 1;
  String? userId;

  late SupabaseClient _client;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    initializeDateFormatting('bs');
    _initializeSupabase();
    listenForNotifications();
    _getUserId();
    _getTasks();
  }

  void _initializeSupabase() {
     _client = SupabaseClient('${dotenv.env['SUPABASE_URL']}', '${dotenv.env['SUPABASE_ANON_KEY']}');

  }

  Future<void> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userid');
      firstname = prefs.getString('firstname').toString();
      lastname = prefs.getString('lastname').toString();
    });
  }


  void initializeService() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,

        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'AWESOME SERVICE',
        initialNotificationContent: 'Initializing',
        foregroundServiceNotificationId: 888,
      ),

      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onBackground,
      ),
    );
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      SharedPreferences prefs2 = await SharedPreferences.getInstance();
      final userId = prefs2.getString('userid');
      if (userId != null && userId != '') {
        await listenForNotifications();
      }
    });
  }
  FutureOr<bool> onBackground(ServiceInstance service) async {
    await listenForNotifications();
    return true;
  }


  Future<void> onStart(ServiceInstance service) async {
    listenForNotifications();
  }
  Future<void> _getTasks() async {
    final response = await _client
        .from('tasks')
        .select();

    final List<dynamic> taskResults = response;

    final tasks = taskResults.map((row) {
        return {
        'id': row['id'],
        'startTime': row['startTime'],
        'endTime': row['endTime'],
        'activity': row['activity'],
        'date': row['date'],
        'location': row['location'],
        'priority': row['priority'],
        'progress': row['progress'],
        'status': row['status'],
        'userId': row['userId'],
        'parentId': row['parentId']
      };
    }).toList();

    if (mounted) {
      setState(() {
        _tasks = tasks;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    if (isToday(date)) {
      return 'Danas';
    } else {
      return DateFormat('EEEE, dd. MMMM', 'bs_BA').format(date);
    }
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _selectButton(int index) {
    setState
      (() {
      _selectedButtonIndex = index;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        return;
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditProfile()),
        );
      }
    });
  }
  Future<void> listenForNotifications() async {
    await dotenv.load(fileName: 'resource.env');
    final connection = PostgreSQLConnection(
      dotenv.env['DB_HOST']!,
      int.parse(dotenv.env['DB_PORT']!),
      dotenv.env['DB_DATABASE']!,
      username: dotenv.env['DB_USER']!,
      password: dotenv.env['DB_PASSWORD']!,
    );

    await connection.open();
    await connection.query("LISTEN new_task_added");

    connection.notifications.listen((event) {
      print("new task added");
      if (event.channel == 'new_task_added') {
        if (mounted) {
          setState(() {
_getTasks();
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFDB4D),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.subtract(Duration(days: 1));
                });
              },
            ),
            Spacer(),
            Text(
              _formatDate(_selectedDate),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.add(Duration(days: 1));
                });
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavigationButton(0, 'U toku', Colors.lightBlueAccent),
                _buildNavigationButton(1, 'Za obaviti', Colors.grey),
                _buildNavigationButton(2, 'Završeno', Colors.lightGreenAccent),
              ],
            ),
          ),
          Expanded(
            child: _buildPageContent(_selectedButtonIndex),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildNavigationButton(int index, String text, Color color) {
    return ElevatedButton(
      onPressed: () => _selectButton(index),
      style: ElevatedButton.styleFrom(backgroundColor: _selectedButtonIndex == index ? color : null),
      child: Text(text),
    );
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
  String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }
  DateTime parseDate(dynamic date) {
    if (date is String) {
      return DateTime.parse(date);
    } else if (date is DateTime) {
      return date;
    } else {
      throw ArgumentError('Invalid date format');
    }
  }

  Widget _buildPageContent(int index) {
    List<Map<String, dynamic>> filteredTasks = [];
    DateTime appBarDate = _selectedDate
    ;
    if (index == 0) {
      filteredTasks = _tasks.where((task) =>
      task['status'] == 1 &&
          (userId!.trim()) == (task['userId']).toString() &&
          isSameDate(appBarDate, DateTime.parse(task['date']))).toList();
    } else if (index == 1) {
      filteredTasks = _tasks.where((task) =>
      task['status'] == 0 &&
          (userId!.trim()) == (task['userId']).toString() &&
          isSameDate(appBarDate, DateTime.parse(task['date']))).toList();
    } else if (index == 2) {
      filteredTasks = _tasks.where((task) =>
      task['status'] == 2 &&
          (userId!.trim()) == (task['userId']).toString() &&
          isSameDate(appBarDate, DateTime.parse(task['date']))).toList();
    } else {
      filteredTasks = [];
    }

    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {

        final task = filteredTasks[index];
        return TaskCard(
            startTime: (task['startTime']),
            endTime: (task['endTime']),
            activity: task['activity'],
            progress: task['progress'],
            location: task['location'] ?? '',
            status: task['status'],
            taskId: task['id'],
            activityName: task['activity'],
            date: parseDate(task['date']),
            priority: task['priority'],
            parentId: task['parentId'],
            firstName:firstname,
            lastName: lastname,
            refreshTasks: refreshTasks
        );
      },
    );

  }
}
