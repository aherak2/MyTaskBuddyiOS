import 'package:diplomski/components/StepNumber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class SubsetCard extends StatefulWidget {
  final String stepName;
  final String description;
  final int id;
  final int taskId;
  final int status;
  final Function getSubsets;
  final Function refreshListView;

  SubsetCard({
    required this.taskId,
    required this.status,
    required this.stepName,
    required this.description,
    required this.id,
    required this.getSubsets,
    required this.refreshListView,
    Key? key
  }) : super(key: key);

  @override
  _SubsetCardState createState() => _SubsetCardState(
    id: id,
    status: status,
    stepName: stepName,
    description: description,
    taskId: taskId,
    getSubsets: getSubsets,
    refreshListView: refreshListView,
  );
}

class _SubsetCardState extends State<SubsetCard> {
  late int _id;
  late int _status;
  late String _stepName;
  late String _description;
  late int _taskId;
  late Function _getSubsets;
  late String buttonText = "Dalje";
  late Function _refreshListView;
  late int? _firstNotCompletedId = 0;

  _SubsetCardState({required int id, required int status, required String stepName, required String description, required int taskId, required Function getSubsets, required Function refreshListView}) {
    _id = id;
    _status = status;
    _stepName = stepName;
    _description = description;
    _taskId = taskId;
    _getSubsets = getSubsets;
    _refreshListView = refreshListView;
  }

  void initState() {
    super.initState();
    _initializeState();
  }

  Future<void> _initializeState() async {
    var subsets = await _getSubsets();
    late Map<String, dynamic>? firstSubsetWithStatus0;

    try {
      firstSubsetWithStatus0 = subsets.firstWhere(
            (subset) => subset['status'] == 0,
      );
      setState(() {
        _firstNotCompletedId = firstSubsetWithStatus0?['id'];
        print(_firstNotCompletedId);
        _refreshListView();
        buttonText = (_status == 0) ? 'Dalje' : 'Završeno';
      });
    } catch (e) {
      _firstNotCompletedId = -1;
    }
  }

  void showBadgeAlert(String badgeName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Čestitamo!"),
          content: const Text("Osvojili ste novi bedž"),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Future<void> _finishSubstep() async {
    final connection = PostgreSQLConnection(
      '${dotenv.env['DB_HOST']}',
      int.parse('${dotenv.env['DB_PORT']}'),
      '${dotenv.env['DB_DATABASE']}',
      username: '${dotenv.env['DB_USER']}',
      password: '${dotenv.env['DB_PASSWORD']}',
    );
    await connection.open();

    // Update the status of the current substep
    await connection.execute('''
      UPDATE substeps 
      SET status = 1
      WHERE id = @id
    ''', substitutionValues: {
      'id': _id,
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userid');
    final taskResults = await connection.query('SELECT * FROM tasks WHERE "userId" = @userId', substitutionValues: {
      'userId': userId,
    });
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
    }).where((task) =>
    isSameDate(DateTime.now(), task['date']) && (userId!.trim()) == (task['userId']).toString()).toList();


    final substepResults = await connection.query('SELECT * FROM substeps');
    List<Map<String, dynamic>> substeps = substepResults.map((row) {
      return {
        'id': row[0],
        'status': row[4],
        'taskId': row[3],
      };
    }).toList();

    final substep = substeps.where((substep1) =>
    substep1['taskId'] == _taskId
    ).toList();

    int completedSubsteps = substep.where((s) => s['status'] == 1).length;
    int totalSubsteps = substep.length;
    int progress = ((completedSubsteps / totalSubsteps) * 100).round();

    if (completedSubsteps == totalSubsteps) {
      await connection.execute('''
        UPDATE tasks 
        SET status = 2, progress = 100
        WHERE id = @id
      ''', substitutionValues: {
        'id': _taskId,
      });
    } else {
      await connection.execute('''
        UPDATE tasks 
        SET status = 1, progress = @progress
        WHERE id = @id
      ''', substitutionValues: {
        'id': _taskId,
        'progress': progress,
      });
    }
    final tasks2 = await connection.query('SELECT * FROM tasks');
    List<Map<String, dynamic>> tasksCompleted = tasks2.map((row) {
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
    }).where((task) => (userId!.trim()) == (task['userId']).toString() && task['status']==2).toList();

    int completedTasks = tasksCompleted.length;

    if (completedTasks % 5 == 0) {
      String badgeLevel;
      if (completedTasks <= 30) {
        badgeLevel = 'bronze${completedTasks ~/ 5}';
      } else if (completedTasks <= 90) {
        badgeLevel = 'silver${(completedTasks - 30) ~/ 10}';
      } else if (completedTasks <= 180) {
        badgeLevel = 'gold${(completedTasks - 90) ~/ 15}';
      } else {
        badgeLevel = 'platinum${(completedTasks - 180) ~/ 20}';
      }
      showBadgeAlert(badgeLevel);
    }

    await connection.close();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<int>(_id),
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _id != _firstNotCompletedId ? (_status == 1 ? const Color(0xff00b386) : Colors.grey) : Colors.blue,
          width: 3.3,
        ),
        color: _status == 1 ? const Color(0xffe6fff5) : Colors.white,
      ),
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.08,
                  child: Center(
                    child: Positioned(
                      left: -MediaQuery.of(context).size.width * 0.14 / 2,
                      top: -MediaQuery.of(context).size.width * 0.14 / 2,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.14,
                        height: MediaQuery.of(context).size.width * 0.14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: _status == 1 ? const Color(0xff00b386) : Colors.grey,
                            width: 3.3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _id.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: MediaQuery.of(context).size.width * 0.05,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stepName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _status == 1 ? const Color(0xff00b386) : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _description,
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _id != _firstNotCompletedId
                        ? (_status == 1 ? const Color(0xff00b386) : Colors.white)
                        : Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  ),
                  onPressed: () async {
                    if (_id == _firstNotCompletedId) {
                      await _finishSubstep();
                      setState(() {
                        _status = 1;
                        _initializeState();
                      });
                    }
                  },
                  child: _id == _firstNotCompletedId && _status != 1
                      ? const Text(
                    'Dalje',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : _status == 1
                      ? const Text(
                    'Završeno',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : const Icon(
                    Icons.lock,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
