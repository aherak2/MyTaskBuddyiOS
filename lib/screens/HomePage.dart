import 'package:diplomski/screens/EditProfile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../components/CustomBottomNavigationBar.dart';
import '../components/TaskCard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('bs');
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
  late String firstname,lastname;
  void refreshTasks() {
    _getTasks();
  }
  List<Map<String, dynamic>> _tasks = [];
  int _selectedIndex = 0;
  DateTime _selectedDate = DateTime.now();
  int _selectedButtonIndex = 1;
  String? userId;


  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    initializeDateFormatting('bs');
    _getUserId();
    _getTasks();
  }

  Future<void> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userid');
      firstname=prefs.getString('firstname').toString();
      lastname=prefs.getString('lastname').toString();
    });
  }

  Future<void> _getTasks() async {
    final connection = PostgreSQLConnection(
      '${dotenv.env['DB_HOST']}',
      int.parse('${dotenv.env['DB_PORT']}'),
      '${dotenv.env['DB_DATABASE']}',
      username: '${dotenv.env['DB_USER']}',
      password: '${dotenv.env['DB_PASSWORD']}',
    );

    await connection.open();
    final taskResults = await connection.query('SELECT * FROM tasks');
    List<int> row = [0, 0, 0, 11, 134, 3, 63, 64];
    int sati = row[3];
    int minute = row[4];
    int sekunde = row[5];

    // Dodajemo milisekunde na sekunde
    int milisekunde = row[6] * 1000 + row[7];

    // Stvaramo DateTime objekt
    DateTime vrijeme = DateTime(1970, 1, 1, sati, minute, sekunde, milisekunde);

    print('Vrijeme je: ${vrijeme.hour}:${vrijeme.minute}:${vrijeme.second}.${vrijeme.millisecond}');

    final tasks = taskResults.map((row) {

      return {
        'id': row[0],
        'startTime': row[3],
        'endTime': row[4],
        'activity': row[1],
        'date': row[2],
        'location': row[5],
        'priority': row[6],
        'progress': row[7],
        'status': row[8],
        'userId': row[9],
        'parentId':row[10]
      };
    }).toList();
    setState(() {
      _tasks = tasks;
    });
    await connection.close();
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
    setState(() {
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
  Widget _buildPageContent(int index) {
    List<Map<String, dynamic>> filteredTasks = [];
    DateTime appBarDate = _selectedDate;

    if (index == 0) {
      filteredTasks = _tasks.where((task) =>
      task['status'] == 1 &&
          (userId!.trim()) == (task['userId']).toString() &&
          isSameDate(appBarDate, task['date'])).toList();
    } else if (index == 1) {
      filteredTasks = _tasks.where((task) =>
      task['status'] == 0 &&
          (userId!.trim()) == (task['userId']).toString() &&
          isSameDate(appBarDate, task['date'])).toList();
    } else if (index == 2) {
      filteredTasks = _tasks.where((task) =>
      task['status'] == 2 &&
          (userId!.trim()) == (task['userId']).toString() &&
          isSameDate(appBarDate, task['date'])).toList();
    } else {
      filteredTasks = [];
    }

    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {

        final task = filteredTasks[index];
        return TaskCard(
          startTime: '17:32:32',
          endTime: '18:32:32',
          activity: task['activity'],
          progress: task['progress'],
          location: task['location'] ?? '',
          status: task['status'],
          taskId: task['id'],
          activityName: task['activity'],
          date: task['date'],
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
