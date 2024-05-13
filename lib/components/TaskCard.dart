import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../screens/task.dart'; // Assuming you have a Task screen

class TaskCard extends StatelessWidget {
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

  String formatTime(String time) {
    final List<String> parts = time.split(':');
    return '${parts[0]}:${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final formattedStartTime = formatTime(startTime);
    final formattedEndTime = formatTime(endTime);

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
                  'taskId': taskId,
                  'activityName': activityName,
                  'date': date,
                  'startTime': startTime,
                  'endTime': endTime,
                  'location': location,
                  'parentId': parentId,
                  'firstName': firstName,
                  'status': status,
                },
                refreshTasks: refreshTasks,
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
                    'taskId': taskId,
                    'activityName': activityName,
                    'date': date,
                    'startTime': startTime,
                    'endTime': endTime,
                    'location': location,
                    'parentId': parentId,
                    'firstName': firstName,
                    'status': status,
                  },
                  refreshTasks: refreshTasks,
                ),
              ),
            );
          },
        ),

        title: Container(
          child: Row(
            children: [
              Text(
                activity,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              if (priority == 1)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
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
                  ),
                ),
            ],
          ),
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
                Expanded(

                  child: Text(
                    location,
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(width: 8),
                Image.asset('assets/placeholder.png', width: 20.0, height: 20.0, alignment: Alignment.centerRight),

              ],
            ),


            SizedBox(height: 15),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 100 ? Colors.lightGreen : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}