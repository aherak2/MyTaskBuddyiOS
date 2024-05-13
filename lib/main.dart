import 'dart:io';

import 'package:diplomski/screens/EditProfile.dart';
import 'package:diplomski/screens/HomePage.dart';
import 'package:diplomski/components/Stepper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:postgres/postgres.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: 'resource.env');
  runApp(const MyApp());
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

        print(results);
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
    // Start paint from 20% height to the left
    ovalPath.moveTo(0, height * 0.3);

    // paint a curve from current position to middle of the screen
    ovalPath.quadraticBezierTo(
        width*1.7, height*0.25 , width, height *1.25);

    // Paint a curve from current position to bottom left of screen at width * 0.1
    ovalPath.quadraticBezierTo(width * 1.5, height * 1, width * 0.7, height);

    // draw remaining line to bottom left side
    ovalPath.lineTo(0, height);

    // Close line to reset it back
    ovalPath.close();

    paint.color = Colors.white;
    canvas.drawPath(ovalPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}