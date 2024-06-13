import 'dart:async';
import 'dart:io';
import 'package:add_2_calendar/add_2_calendar.dart' as calendar;
import 'package:diplomski/screens/HomePage.dart';
import 'package:diplomski/components/Stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:postgres/postgres.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase/supabase.dart';
import 'components/background_service.dart';
@pragma(
    'vm:entry-point')
Future<void> main() async {

  await dotenv.load(fileName: 'resource.env');
  final connection = PostgreSQLConnection(
    '${dotenv.env['DB_HOST']}',
    int.parse('${dotenv.env['DB_PORT']}'),
    '${dotenv.env['DB_DATABASE']}',
    username: '${dotenv.env['DB_USER']}',
    password: '${dotenv.env['DB_PASSWORD']}',
  );


  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userid');
  WidgetsFlutterBinding.ensureInitialized();
  NotifyService().initNotification();
  await connection.open();
  await listenForNotifications();

  await connection.close();
  if (userId != null && userId!='') {
    runApp(const MaterialApp(home: HomePage()));
  } else {
    runApp(const MaterialApp(home: MyHomePage(title: 'Prijava')));
  }
}
 SupabaseClient _client=SupabaseClient('${dotenv.env['SUPABASE_URL']}', '${dotenv.env['SUPABASE_ANON_KEY']}');

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


Future<void> createTrigger(PostgreSQLConnection connection) async {
  try {
    await connection.query('''
      CREATE TRIGGER my_trigger
      AFTER INSERT ON tasks
      FOR EACH ROW
      EXECUTE PROCEDURE my_function();
    ''');
    print('Trigger created successfully.');
  } catch (e) {
    print('Error creating trigger: $e');
  }
}

Future<void> createFunction(PostgreSQLConnection connection) async {
  try {
    await connection.query('''
      CREATE OR REPLACE FUNCTION my_function() RETURNS TRIGGER AS \$\$ 
      BEGIN
        PERFORM pg_notify('new_task_added', '');
        RETURN NEW;
      END;
      \$\$  LANGUAGE plpgsql;
''');
    print('Function created successfully.');
  } catch (e) {
    print('Error creating function: $e');
  }
}

void addTaskToCalendar(String title, DateTime startTime, DateTime endTime, String location) {
  final event = calendar.Event(
    title: title,
    location: location,
    startDate: startTime,
    endDate: endTime,
    iosParams: const calendar.IOSParams(
      reminder: Duration(minutes: 15),
    ),
  );



  calendar.Add2Calendar.addEvent2Cal(event);
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

  connection.notifications.listen((event) async {
    if (event.channel == 'new_task_added') {
      final taskInfo = await getTaskInfo(connection, event.payload);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userid');

      if (taskInfo != null && isToday(taskInfo['date'] )&& taskInfo['userId'].toString()==userId) {
        NotifyService().showNotification(
          title: 'MyTaskBuddy',
          body: 'Dodan je novi zadatak!',
        );
      }
    }
  });
}

Future<Map<String, dynamic>?> getTaskInfo(PostgreSQLConnection connection, String? taskId) async {
  final results = await connection.query('SELECT * FROM tasks WHERE id = @taskId', substitutionValues: {'taskId': taskId});
  if (results.isNotEmpty) {
    final row = results.first;
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
  }
  return null;
}

bool isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month && date.day == now.day;
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diplomski rad',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.blueAccent),

      ),
      home: const MyHomePage(title: 'Prijava'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title});

  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = '';
  bool _isPasswordVisible = false;

  Future<void> _handleLogin() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();
    final connection = PostgreSQLConnection(
      '${dotenv.env['DB_HOST']}',
      int.parse('${dotenv.env['DB_PORT']}'),
      '${dotenv.env['DB_DATABASE']}',
      username: '${dotenv.env['DB_USER']}',
      password: '${dotenv.env['DB_PASSWORD']}',
    );

    await connection.open();

    final results = await connection.query('SELECT * FROM users WHERE username = @username AND password = @password', substitutionValues: {
      'username': username,
      'password': password,
    });
    if (results.isEmpty) {
      setState(() {
        _message = 'Neispravno korisničko ime ili lozinka';
      });
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('userid', results.first.first.toString());
      prefs.setString('firstname', results.first[1].toString());
      prefs.setString('lastname', results.first[2].toString());

      setState(() {
        _message = '';
      });
      await connection.close();

      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomePage())
      );
    }

  }
  void _handleRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyStepper()),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: CustomPaint(
        painter:BluePainter(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Transform.translate(


                  offset:  const Offset(0.0, -125.0),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 150,
                    height: 150,
                  )
              )
              ,
              const Text(
                'Prijava',
                style: TextStyle(
                  fontSize: 42.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Prijavi se da nastaviš.',
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
              Container(
                  alignment: Alignment.centerLeft,
                  child:const Text(
                    'KORISNIČKO IME',
                    textAlign: TextAlign.left,
                  )
              ),
              TextField(
                controller: _usernameController,
                decoration:  InputDecoration( border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                )),

              ),
              Container(
                  alignment: Alignment.centerLeft,
                  child:const Text(
                    'LOZINKA',
                    textAlign: TextAlign.left,
                  )
              )
              ,
              TextField(
                controller: _passwordController,
                decoration:  InputDecoration( border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
              if (_message.isNotEmpty)
                Text(
                  _message,
                  style: const TextStyle(color: Colors.red,fontWeight: FontWeight.bold),
                ),
              SizedBox(
                width: double.infinity,
                child:  ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Prijavi se',
                    style: TextStyle(fontSize: 16.0,color: Colors.white),
                  ),

                ),
              )
              ,
              const SizedBox(height: 20.0,
                child:Text('Nemate račun?'),
              ),
              SizedBox(
                width: double.infinity,
                child:  ElevatedButton(
                  onPressed: _handleRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                  ),
                  child: Text(
                    'Registruj se',
                    style: TextStyle(fontSize: 16.0,color: Colors.black),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );

  }

}
class BluePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;
    Paint paint = Paint();

    Path mainBackground = Path();
    mainBackground.addRect(Rect.fromLTRB(0, 0, width, height));
    paint.color = Colors.blue.shade900;
    canvas.drawPath(mainBackground, paint);

    Path ovalPath = Path();
    ovalPath.moveTo(0, height * 0.3);

    ovalPath.quadraticBezierTo(
        width*1.7, height*0.25 , width, height *1.25);

    ovalPath.quadraticBezierTo(width * 1.5, height * 1, width * 0.7, height);

    ovalPath.lineTo(0, height);

    ovalPath.close();

    paint.color = Colors.white;
    canvas.drawPath(ovalPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}