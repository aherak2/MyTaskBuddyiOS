import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diplomski/components/avatar_picker.dart';
import 'package:diplomski/components/user_input.dart';

class registration extends StatefulWidget {
  const registration({Key? key}) : super(key: key);

  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<registration> {
  final List<Map<String, dynamic>> avatars = [
    {'id': 1, 'url': 'https://cdn-icons-png.flaticon.com/512/847/847969.png'},
    {'id': 2, 'url': 'https://cdn-icons-png.flaticon.com/512/4333/4333609.png'},
    {'id': 3, 'url': 'https://cdn-icons-png.flaticon.com/512/1154/1154448.png'},
    {'id': 4, 'url': 'https://cdn-icons-png.flaticon.com/512/1154/1154455.png'},
    {'id': 5, 'url': 'https://cdn-icons-png.flaticon.com/512/706/706831.png'},
    {'id': 6, 'url': 'https://cdn-icons-png.flaticon.com/512/1154/1154955.png'},
    {'id': 7, 'url': 'https://cdn-icons-png.flaticon.com/512/1154/1154480.png'},
  ];

  late Map<String, dynamic> selectedAvatar = avatars[0];
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }


  Future<void> _handleSubmit() async {
    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    final selectedAvatarUrl = avatars[0]['url'];

    if (firstName.isEmpty || lastName.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Greška'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Morate unijeti ime i prezime.'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    final connection = PostgreSQLConnection(
      '${dotenv.env['DB_HOST']}',
      int.parse('${dotenv.env['DB_PORT']}'),
      '${dotenv.env['DB_DATABASE']}',
      username: '${dotenv.env['DB_USER']}',
      password: '${dotenv.env['DB_PASSWORD']}',
    );

    try {
      await connection.open();

      final results = await connection.query('''
      SELECT * FROM users WHERE firstname = @firstName
    ''', substitutionValues: {
        'firstName': firstName,
      });

      if (results.isNotEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Greška'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('Korisnik već postoji sa unesenim imenom.'),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        final results1 = await connection.query('''
        INSERT INTO users (firstname, lastname, avatar)
        VALUES (@firstName, @lastName, @selectedAvatarUrl)
        RETURNING id
      ''', substitutionValues: {
          'firstName': firstName,
          'lastName': lastName,
          'selectedAvatarUrl': selectedAvatarUrl,
        });

        if (results1.isNotEmpty) {
          final userId = results1.first.first as int;
        }
      }

      await connection.close();
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    }
  }


    @override
    Widget build(BuildContext context) {
      return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFFFFDB4D),
          ),
          body: CustomPaint(
            painter: YellowPainter(),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[

                  Transform.translate(
                    offset: const Offset(0.0, -50),
                    child: const Text(
                      'Registracija',
                      style: TextStyle(
                        fontSize: 42.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Transform.translate(
                      offset: const Offset(0.0, -40.0),
                      child:
                      AvatarPicker(
                        avatars: const [
                          {
                            'id': 1,
                            'url': 'https://cdn-icons-png.flaticon.com/512/847/847969.png'
                          },
                          {
                            'id': 2,
                            'url': 'https://cdn-icons-png.flaticon.com/512/4333/4333609.png'
                          },
                          {
                            'id': 3,
                            'url': 'https://cdn-icons-png.flaticon.com/512/1154/1154448.png'
                          },
                          {
                            'id': 4,
                            'url': 'https://cdn-icons-png.flaticon.com/512/1154/1154455.png'
                          },
                          {
                            'id': 5,
                            'url': 'https://cdn-icons-png.flaticon.com/512/706/706831.png'
                          },
                          {
                            'id': 6,
                            'url': 'https://cdn-icons-png.flaticon.com/512/1154/1154955.png'
                          },
                          {
                            'id': 7,
                            'url': 'https://cdn-icons-png.flaticon.com/512/1154/1154480.png'
                          },
                        ],
                        onSelectAvatar: (avatar) {
                          setState(() {
                            selectedAvatar = avatar;
                          });
                        },
                      )),
                  Container(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'UNESI IME',
                        textAlign: TextAlign.left,
                      )
                  ),
                  TextField(controller: _firstNameController,
                      decoration: InputDecoration(border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ))),
                  Container(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'UNESI PREZIME',
                        textAlign: TextAlign.left,
                      )
                  ),
                  TextField(controller: _lastNameController,
                      decoration: InputDecoration(border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ))),


                  ElevatedButton(
                    onPressed: () {
_handleSubmit();
},
                    child: Text('Register'),
                  ),

                ],
              ),
            ),
          )
      );
    }

  void _handleSelectAvatar(Map<String, dynamic> avatar) {
    setState(() {
      selectedAvatar = avatar;
    });
    print('Selected avatar: $avatar');
  }

  void _handleBackButtonPress() {
    Navigator.of(context).pop();
  }

  void _onNextStep() {
    print('Called next step');
  }

  void _onPrevStep() {
    print('Called previous step');
  }

  Future<void> _onSubmitSteps() async {
    print('Called on submit step.');
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/users/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'firstname': _firstNameController.text,
          'lastname': _lastNameController.text,
          'avatar': selectedAvatar['url'],
        }),
      );
      if (response.statusCode == 200) {
        final userId = jsonDecode(response.body)['userId'];

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);


      }
    } catch (error) {
      print(error.toString());
      setState(() {
        _error = error.toString();
      });
    }
  }
}
class YellowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;
    Paint paint = Paint();

    Path mainBackground = Path();
    mainBackground.addRect(Rect.fromLTRB(0, 0, width, height));
    paint.color = const Color(0xFFFFDB4D);
    canvas.drawPath(mainBackground, paint);

    Path ovalPath = Path();
    // Start paint from 20% height to the left
    ovalPath.moveTo(0, height * 0.05);

    // paint a curve from current position to middle of the screen
    ovalPath.quadraticBezierTo(
        width*1.7, height*0.06 , width, height *0.6);

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