import 'package:diplomski/main.dart';
import 'package:diplomski/screens/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/CustomBottomNavigationBar.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  int _selectedIndex = 1;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _allTasks = [];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if(index==1) {
        return;
      } else {
        Navigator.pop(context);
      }
    });
  }
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _avatar = '';
  String _firstName = '';
  String _lastName = '';
  bool _isPasswordVisible = false;
  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> handleChanges() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userid');
      if (userId != null) {
        final connection = PostgreSQLConnection(
          '${dotenv.env['DB_HOST']}',
          int.parse('${dotenv.env['DB_PORT']}'),
          '${dotenv.env['DB_DATABASE']}',
          username: '${dotenv.env['DB_USER']}',
          password: '${dotenv.env['DB_PASSWORD']}',
        );

        await connection.open();

        final response = await connection.execute('''
        UPDATE users 
        SET 
          username = @username,
          password = @password
        WHERE
          id = @id
      ''', substitutionValues: {
          'username': _usernameController.text,
          'password': _passwordController.text,
          'id': userId,
        });

        await connection.close();
if(response==1){
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Profile updated successfully"),
              actions: [
                ElevatedButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }}
    } catch (error) {
      print('Error editing profile: $error');
    }
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

Future<void> badgeControl() async {
  final connection = PostgreSQLConnection(
    '${dotenv.env['DB_HOST']}',
    int.parse('${dotenv.env['DB_PORT']}'),
    '${dotenv.env['DB_DATABASE']}',
    username: '${dotenv.env['DB_USER']}',
    password: '${dotenv.env['DB_PASSWORD']}',
  );

  await connection.open();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userid');
  final taskResults = await connection.query('SELECT * FROM tasks');
  List<Map<String, dynamic>> tasks = taskResults.map((row) {
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
  }).where((task)=>
  isSameDate( DateTime.now(), task['date']) && (userId!.trim()) == (task['userId']).toString()).toList();
  final substepResults = await connection.query('SELECT * FROM substeps');
  List<Map<String, dynamic>> substeps = substepResults.map((row) {
    return {
      'id': row[0],
      'status': row[4],
      'taskId': row[3],
    };
  }).toList();

  setState(() {
    _allTasks=substeps.where((substep)=>
        tasks.any((task) => task['id'] == substep['taskId'])).toList();

    _tasks =  substeps.where((substep) =>
    tasks.any((task)=>task['id'] == substep['taskId']) && substep['status']==1
    ).toList();
    print(_tasks);
  });
  await connection.close();
}

  Future<void> fetchUserDetails() async {
    try {
      badgeControl();
      print("uslo");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userid');
      if (userId != null) {
          final connection = PostgreSQLConnection(
            '${dotenv.env['DB_HOST']}',
            int.parse('${dotenv.env['DB_PORT']}'),
            '${dotenv.env['DB_DATABASE']}',
            username: '${dotenv.env['DB_USER']}',
            password: '${dotenv.env['DB_PASSWORD']}',
          );

          await connection.open();

          final results = await connection.query('SELECT * FROM users WHERE id = @id', substitutionValues: {
            'id': userId,
          });

          await connection.close();

          if (results.isNotEmpty) {
            setState(() {
                  _avatar = results.first[5];
                 _firstName = results.first[1];
               _lastName = results.first[2];
              _usernameController.text = results.first[3];
              _passwordController.text =  results.first[4];
            });
     }
      }
    } catch (error) {
      print('Error fetching details: $error');
    }
  }
  Future<void> handleSwitch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('userid', '');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyApp()),
    );
  }
  double calculateProgress() {
    int totalGoals =  _allTasks.length;

    int completedTasks = _tasks.length;

    if (totalGoals == 0) {
      return 0.0;
    }

    double progress = completedTasks / totalGoals;

    return progress;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uredi profil' ,
          style: TextStyle(
          fontWeight: FontWeight.bold,
        ),),
        backgroundColor: const Color(0xFFCCEEFF),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_avatar.isNotEmpty)
                Image.network(
                  _avatar,
                  width: MediaQuery.of(context).size.width * 0.2,
                  height: MediaQuery.of(context).size.width * 0.3,
                ),
              Text(
                '$_firstName $_lastName',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Novo korisničko ime',
                  prefixIcon: Icon(Icons.person, color: Colors.green),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Nova lozinka',
                  prefixIcon: Icon(Icons.lock, color: Colors.blue),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: handleChanges,
                child: Text('Sačuvaj promjene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFCCEEFF),
                ),
              ),
              SizedBox(height: 20),
              const Text(
                'Napredak',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              LinearProgressIndicator(
                value: calculateProgress(),
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF99CCFF)),
              ),
              SizedBox(height: 10),
              Text(
                'Ciljevi: ${_tasks.length}/${_allTasks.length}',
                style: TextStyle(fontSize: 16),
              ),
              Row(
                children: [
                  if (_tasks.length / _allTasks.length * 100 >= 20)
                    Image.asset(
                      'assets/bronze.png',
                      width: 70,
                      height: 70,
                    ),
                  SizedBox(width: 20),
                  if (_tasks.length / _allTasks.length * 100 >= 40)
                    Image.asset(
                      'assets/silver.png',
                      width: 70,
                      height: 70,
                    ),
                  SizedBox(width: 20),
                  if (_tasks.length / _allTasks.length * 100 >= 60)
                    Image.asset(
                      'assets/gold.png',
                      width: 70,
                      height: 70,
                    ),
                  SizedBox(width: 20),
                  if (_tasks.length / _allTasks.length * 100 >= 80)
                    Image.asset(
                      'assets/platinum.png',
                      width: 70,
                      height: 70,
                    ),
                ],
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              TextButton(
                onPressed: handleSwitch,
                child: Text('Prijavi se s drugog računa'),
              ),
            ],
          ),

        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
