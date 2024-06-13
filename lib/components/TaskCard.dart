import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/Task.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as calendar;

class TaskCard extends StatefulWidget {
  final String startTime;
  final String endTime;
  final String activity;
  final int progress;
  final String location;
  final int priority;
  final int parentId;
  final DateTime date;
  final String firstName;
  final String lastName;
  final String activityName;
  final int taskId;
  final int status;
  final Function refreshTasks;

  TaskCard({
    required this.startTime,
    required this.endTime,
    required this.activity,
    required this.progress,
    required this.location,
    required this.priority,
    required this.parentId,
    required this.date,
    required this.firstName,
    required this.lastName,
    required this.activityName,
    required this.taskId,
    required this.status,
    required this.refreshTasks,
  });

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool isDa = true;
  bool isAddedToCalendar = false;
  Future<void> addTaskToCalendar(String title, DateTime startTime, DateTime endTime, String location) async {
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAddedToCalendar${widget.taskId}', true);

    setState(() {
      isAddedToCalendar = true;
    });

  }

  @override
  void initState() {
    super.initState();
    fetchInitialHelpValue();
    checkCalendarEventStatus();
  }

  Future<void> checkCalendarEventStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isAdded = prefs.getBool('isAddedToCalendar${widget.taskId}') ?? false;
    setState(() {
      isAddedToCalendar = isAdded;
    });
  }

  Future<void> fetchInitialHelpValue() async {
    final connection = PostgreSQLConnection(
      '${dotenv.env['DB_HOST']}',
      int.parse('${dotenv.env['DB_PORT']}'),
      '${dotenv.env['DB_DATABASE']}',
      username: '${dotenv.env['DB_USER']}',
      password: '${dotenv.env['DB_PASSWORD']}',
    );

    await connection.open();

    final results = await connection.query(
      'SELECT help FROM tasks WHERE id = @taskId',
      substitutionValues: {'taskId': widget.taskId},
    );

    if (results.isNotEmpty) {
      setState(() {
        isDa = results[0][0] == 0;
      });
    }
    await connection.close();
  }

  String formatTime(String time) {
    final List<String> parts = time.split(':');
    return '${parts[0]}:${parts[1]}';
  }

  Future<void> toggleButton() async {
    setState(() {
      isDa = !isDa;
    });

    final connection = PostgreSQLConnection(
      '${dotenv.env['DB_HOST']}',
      int.parse('${dotenv.env['DB_PORT']}'),
      '${dotenv.env['DB_DATABASE']}',
      username: '${dotenv.env['DB_USER']}',
      password: '${dotenv.env['DB_PASSWORD']}',
    );

    await connection.open();

    await connection.execute('''
    UPDATE tasks 
    SET help = @help
    WHERE id = @taskId
  ''', substitutionValues: {
      'help': isDa ? 0 : 1,
      'taskId': widget.taskId,
    });

    await connection.close();
  }

  @override
  Widget build(BuildContext context) {
    final formattedStartTime = formatTime(widget.startTime);
    final formattedEndTime = formatTime(widget.endTime);

    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: Offset(0, 2),
            blurRadius: 3.84,
          ),
        ],
        border: Border.all(
          color: Color(0xFFC8C8C8),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Task(
                route: {
                  'taskId': widget.taskId,
                  'activityName': widget.activityName,
                  'date': widget.date,
                  'startTime': widget.startTime,
                  'endTime': widget.endTime,
                  'location': widget.location,
                  'parentId': widget.parentId,
                  'firstName': widget.firstName,
                  'status': widget.status,
                },
                refreshTasks: widget.refreshTasks,
              ),
            ),
          );
        },
        trailing: IconButton(
          icon: Icon(Icons.more_vert),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Task(
                  route: {
                    'taskId': widget.taskId,
                    'activityName': widget.activityName,
                    'date': widget.date,
                    'startTime': widget.startTime,
                    'endTime': widget.endTime,
                    'location': widget.location,
                    'parentId': widget.parentId,
                    'firstName': widget.firstName,
                    'status': widget.status,
                  },
                  refreshTasks: widget.refreshTasks,
                ),
              ),
            );
          },
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.activity,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            if (widget.priority == 1)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFCCCC),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'HITNO',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset('assets/clock.png', width: 20.0, height: 20.0),
                SizedBox(width: 8),
                Text('$formattedStartTime - $formattedEndTime'),
                Spacer(),
                Text(
                  widget.location,
                  textAlign: TextAlign.right,
                ),
                SizedBox(width: 8),
                Image.asset('assets/placeholder.png', width: 20.0, height: 20.0),
              ],
            ),
            SizedBox(height: 15),
            LinearProgressIndicator(
              value: widget.progress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.progress == 100 ? Colors.lightGreen : Colors.blue,
              ),
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Text('Potrebna pomoć?'),
                ),
                ElevatedButton(
                  onPressed: toggleButton,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDa? Colors.blueAccent.shade200:Colors.blueAccent.shade100,
                  ),
                  child: Text(
                    isDa ? 'NE' : 'DA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAddedToCalendar ? Colors.blue.shade300 : Colors.blue.shade400,
                ),
                onPressed:
                     () {
                  if(!isAddedToCalendar) {
                    addTaskToCalendar(
                    widget.activityName,
                    widget.date.add(Duration(hours: int.parse(widget.startTime.split(":")[0]), minutes: int.parse(widget.startTime.split(":")[1]))),
                    widget.date.add(Duration(hours: int.parse(widget.endTime.split(":")[0]), minutes: int.parse(widget.endTime.split(":")[1]))),
                    'Location: ${widget.location}',
                  );
                  }
                },
                child:  Text(
                  !isAddedToCalendar ? 'Dodajte u kalendar' : 'Dodano u kalendar',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
