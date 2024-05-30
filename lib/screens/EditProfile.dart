import 'package:diplomski/main.dart';
import 'package:flutter/material.dart';
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
  int _bronzeLevel = 0;
  int _silverLevel = 0;
  int _goldLevel = 0;
  int _platinumLevel = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
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
        if (response == 1) {
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
        }
      }
    } catch (error) {
      print('Error editing profile: $error');
    }
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
        'parentId': row[10]
      };
    }).where((task) => (userId!.trim()) == (task['userId']).toString()).toList();

    setState(() {
      _tasks = tasks.where((substep) =>   substep['status'] == 2).toList();
print(_tasks.length);
      int completedTasks = _tasks.length;
      _bronzeLevel = (completedTasks ~/ 5).clamp(0, 6);
      _silverLevel = ((completedTasks - 30) ~/ 5).clamp(0, 6);
      _goldLevel = ((completedTasks - 60) ~/ 5).clamp(0, 6);
      _platinumLevel = ((completedTasks - 90) ~/ 5).clamp(0, 6);
    });

    await connection.close();
  }

  Future<void> fetchUserDetails() async {
    try {
      badgeControl();
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
            _passwordController.text = results.first[4];
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
    int totalGoals = _allTasks.length;
    int completedTasks = _tasks.length;

    if (totalGoals == 0) {
      return 0.0;
    }

    double progress = completedTasks / totalGoals;

    return progress;
  }



  List<Widget> generateBadgeRow(String badgeType, int level) {
    List<Widget> badges = [];
    for (int i = 1; i <= level; i++) {
      badges.add(
        Image.asset(
          'assets/$badgeType$i.png',
          width: 50,
          height: 50,
        ),
      );
    }
    return badges;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Uredi profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFCCEEFF),
          ),
          child: const Text('Sačuvaj promjene')),

              SizedBox(height: 20),
              const Text(
                'Vaše medalje:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),),
              SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: generateBadgeRow('bronze', _bronzeLevel),
                  ),
                  SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    alignment: WrapAlignment.center,
                    runSpacing: 10,
                    children: generateBadgeRow('silver', _silverLevel),
                  ),
                  SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    alignment: WrapAlignment.center,
                    runSpacing: 10,
                    children: generateBadgeRow('gold', _goldLevel),
                  ),
                  SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    alignment: WrapAlignment.center,
                    runSpacing: 10,
                    children: generateBadgeRow('platinum', _platinumLevel),
                  ),
                  if(_bronzeLevel==0)
                    const Text(
                      'Nemate medalja',
                      style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                    ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: handleSwitch,
                    child: Text('Prijavi se s drugog računa'),
                  ),
                ],
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
