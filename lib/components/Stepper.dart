import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/HomePage.dart';
import 'avatar_picker.dart';

void main() {
  runApp(MaterialApp(
    home: MyStepper(),
  ));
}

class MyStepper extends StatefulWidget {
  @override
  _MyStepperState createState() => _MyStepperState();
}

class _MyStepperState extends State<MyStepper> {
  int _currentStep = 0;
  final List<Map<String, dynamic>> avatars = [
    {'id': 1, 'url': 'https://cdn-icons-png.flaticon.com/512/847/847969.png'},
    {'id': 2, 'url': 'https://cdn-icons-png.flaticon.com/512/4333/4333609.png'},
    {'id': 3, 'url': 'https://cdn-icons-png.flaticon.com/512/1154/1154448.png'},
    {'id': 4, 'url': 'https://cdn-icons-png.flaticon.com/512/1154/1154455.png'},
    {'id': 5, 'url': 'https://cdn-icons-png.flaticon.com/512/706/706831.png'},
    {'id': 6, 'url': 'https://cdn-icons-png.flaticon.com/512/1154/1154955.png'},
    {'id': 7, 'url': 'https://cdn-icons-png.flaticon.com/512/1154/1154480.png'},
  ];
  late Map<String, dynamic> selectedAvatar=avatars[0];
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _error = '';
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    selectedAvatar = avatars[0];
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  void _handleSubmit() async {
    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    final selectedAvatarUrl = selectedAvatar['url'];
    final username = _usernameController.text;
    final password = _passwordController.text;

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
        INSERT INTO users (firstname, lastname, avatar, username, password)
        VALUES (@firstName, @lastName, @avatar, @username, @password)
        RETURNING id
      ''', substitutionValues: {
        'firstName': firstName,
        'lastName': lastName,
        'avatar': selectedAvatarUrl,
        'username': username,
        'password': password,
      });

      if (results.isNotEmpty) {
        final userId = results[0][0] as int;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('userid', userId.toString());
        prefs.setString('firstname', firstName);
        prefs.setString('lastname', lastName);
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
    List<Step> _steps = [
      Step(
        title: const Text(''),
        label: const Text('Prvi korak'),
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        content:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Transform.translate(
              offset: const Offset(0.0, 0),
              child: const Text(
                'Registracija',
                style: TextStyle(
                  fontSize: 42.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Transform.translate(
                offset:  const Offset(0.0, 0.0),
                child:
                AvatarPicker(
                  avatars: const [
                    {'id': 1, 'url': 'https://cdn-icons-png.flaticon.com/512/847/847969.png'},
                    {'id': 2, 'url': 'https://cdn-icons-png.flaticon.com/512/4333/4333609.png'},
                    {'id': 3, 'url': 'https://cdn-icons-png.flaticon.com/512/1154/1154448.png'},
                    {'id': 4, 'url': 'https://cdn-icons-png.flaticon.com/512/1154/1154455.png'},
                    {'id': 5, 'url': 'https://cdn-icons-png.flaticon.com/512/706/706831.png'},
                    {'id': 6, 'url': 'https://cdn-icons-png.flaticon.com/512/1154/1154955.png'},
                    {'id': 7, 'url': 'https://cdn-icons-png.flaticon.com/512/1154/1154480.png'},
                  ],
                  onSelectAvatar: (avatar) {
                    setState(() {
                      selectedAvatar = avatar;
                    });
                  },
                )),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children:[
                Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child:Text('Listaj za odabir slike profila',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    )
                ),
                Image.asset(
                  'assets/flick-to-left.png',
                  width: 30,
                  height: 30,
                )
              ],
            ),
            Container(
                alignment: Alignment.centerLeft,
                child:const Text(
                  'UNESI IME',
                  textAlign: TextAlign.left,
                )
            ),                TextField(controller: _firstNameController, decoration:  InputDecoration( border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
            ))),
            Container(
                alignment: Alignment.centerLeft,
                child:const Text(
                  'UNESI PREZIME',
                  textAlign: TextAlign.left,
                )
            ),                TextField(controller: _lastNameController, decoration:  InputDecoration( border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
            )
            )
            ),
          ],

        ),),
      Step(
        title: const Text(''),
        label: const Text('Drugi korak'),
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        content: Column(
          children: <Widget>[
            const Text(
              'Registracija',
              style: TextStyle(
                fontSize: 42.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Image.asset(
              'assets/important.png',
              width: 250,
              height: 250,
            ),
            Container(
                alignment: Alignment.centerLeft,
                child:const Text(
                  'UNESI KORISNIČKO IME',
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
                  'UNESI LOZINKU',
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
            )
          ],),
      ),
      Step(
        title: const Text(''),
        label: const Text('Treći korak'),
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,

        content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:<Widget> [
              const Text('Uspješno napravljen račun!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 42.0,
                ),),
              Image.asset('assets/emoji2.png',width: 400,
                height: 400,),
            ]
        ),),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFDB4D),
        title: Text('Registracija korisnika'),
      ),
      body: CustomPaint(
        painter: YellowPainter(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Theme(
            data: ThemeData(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                background: Colors.transparent,
                primary: Colors.black,
              ),
              indicatorColor: Colors.black,
            ),
            child: Stepper(
              elevation: 0,
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == 0) {
                  if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Alert'),
                          content: SingleChildScrollView(
                            child: ListBody(
                              children: <Widget>[
                                Text('Sva polja trebaju biti popunjena!'),
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
                }

                setState(() {
                  _currentStep < _steps.length - 1 ? _currentStep += 1 : null;
                });
              },
              onStepCancel: () {
                setState(() {
                  _currentStep > 0 ? _currentStep -= 1 : null;
                });
              },
              steps: _steps,
              controlsBuilder: (BuildContext context, ControlsDetails controlsDetails) {
                if (_currentStep == 0) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: controlsDetails.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          shadowColor: Colors.black,
                          backgroundColor: Colors.grey.shade300,
                          side: BorderSide(color: Colors.black, width: 2),
                        ),
                        child: Text('Nastavi'),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: controlsDetails.onStepCancel,
                        style: ElevatedButton.styleFrom(
                          shadowColor: Colors.black,
                          backgroundColor: Colors.grey.shade300,
                          side: BorderSide(color: Colors.black, width: 2),
                        ),
                        child: Text('Vrati se'),
                      ),
                      if (_currentStep == 1)
                        ElevatedButton(
                          onPressed: () async {
                            if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Builder(
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        backgroundColor: Colors.white,
                                        elevation: 8.0,
                                        title: Text('Alert'),
                                        content: SingleChildScrollView(
                                          child: ListBody(
                                            children: <Widget>[
                                              Text('Sva polja trebaju biti popunjena!',style: TextStyle(
                                                color: Colors.black87,
                                              ),),
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
                                },
                              );
                              return;
                            }
                            else{
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
      SELECT * FROM users WHERE username = @username
    ''', substitutionValues: {
        'username': _usernameController.text.toString(),
      });

      if (results.isNotEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Builder(
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  elevation: 8.0,
                  title: Text('Alert'),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: <Widget>[
                        Text('Korisničko ime već postoji',style: TextStyle(
                          color: Colors.black87,
                        ),),
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
          },
        );
        return;
      }
      else
        _handleSubmit();
      setState(() {
        _currentStep += 1;
      });
    }
    catch (error) {
      setState(() {
        _error = error.toString();
      });
    }

                          }},
                          style: ElevatedButton.styleFrom(
                            shadowColor: Colors.black,
                            backgroundColor: Colors.grey.shade300,
                            side: BorderSide(color: Colors.black, width: 2),
                          ),
                          child: Text('Registruj se'),
                        ),
                      if (_currentStep == 2)
                        ElevatedButton(
                          onPressed: finish,
                          style: ElevatedButton.styleFrom(
                            shadowColor: Colors.black,
                            backgroundColor: Colors.grey.shade300,
                            side: BorderSide(color: Colors.black, width: 2),
                          ),
                          child: Text('Nastavi'),
                        ),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
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
  ovalPath.moveTo(0, height * 0.01);

  ovalPath.quadraticBezierTo(width * 1.7, height * 0.02, width, height * 0.5);

  ovalPath.quadraticBezierTo(width * 1.5, height * 1, width * 0.7, height * 1.1);

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
