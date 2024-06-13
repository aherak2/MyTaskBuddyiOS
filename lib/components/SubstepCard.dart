import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';

class SubsetCard extends StatefulWidget {
  final String stepName;
  final String description;
  final int id;
  final int taskId;
  final int status;
  final Function getSubsets;
  final Function refreshListView;
  final Function refreshTasks;
  final int firstnot1;
  final List<Map<String, dynamic>>? subsets;
  final Function finishTask;

  final Function showConfetti;
  final ConfettiController confettiController;
  SubsetCard({
    required this.firstnot1,
    required this.taskId,
    required this.status,
    required this.stepName,
    required this.description,
    required this.id,
    required this.getSubsets,
    required this.refreshListView,
    required this.refreshTasks,
    required this.subsets,
    required this.finishTask,
    required this.showConfetti,
    required this.confettiController,
    Key? key,
  }) : super(key: key);

  @override
  _SubsetCardState createState() => _SubsetCardState(
    id: id,
    firstnot1: firstnot1,
    status: status,
    stepName: stepName,
    description: description,
    taskId: taskId,
    getSubsets: getSubsets,
    refreshListView: refreshListView,
    refreshTasks: refreshTasks,
    subsets: subsets,
    finishTask: finishTask,
    showConfetti: showConfetti,
    confettiController: confettiController,
  );
}

class _SubsetCardState extends State<SubsetCard> with TickerProviderStateMixin {
  late int _id;
  late int _status;
  late String _stepName;
  late String _description;
  late int _taskId;
  late Function _getSubsets;
  late String buttonText = "Dalje";
  late Function _refreshListView;
  late Function _refreshTasks;
  late int? _firstNotCompletedId = 0;
  late Function _showConfetti;

  _SubsetCardState({
    required int id,
    required int status,
    required String stepName,
    required String description,
    required int taskId,
    required Function getSubsets,
    required Function refreshListView,
    required Function refreshTasks,
    List<Map<String, dynamic>>? subsets,
    required int firstnot1,
    required Function finishTask,
    required showConfetti,
    required ConfettiController confettiController,
  }) {
    _id = id;
    _status = status;
    _stepName = stepName;
    _description = description;
    _taskId = taskId;
    _getSubsets = getSubsets;
    _refreshListView = refreshListView;
    _refreshTasks = refreshTasks;
    _showConfetti = showConfetti;
  }
  late int _currentMessageIndex;
  final List<String> _messages = [
    'Bravo! Idemo na naredni korak!',
    'Svaka čast! Sljedeći korak te čeka!',
    'Super! Nastavi dalje!',
    "Fantastično! Idemo dalje!"
  ];
  @override
  void didUpdateWidget(SubsetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.id != oldWidget.id) {}
  }

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  Future<void> _initializeState() async {
    try {
      setState(() {
        _firstNotCompletedId = widget.firstnot1;
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
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
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

    await connection.execute('''
      UPDATE substeps 
      SET status = 1
      WHERE id = @id
    ''', substitutionValues: {
      'id': _id,
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userid');
    final taskResults = await connection.query(
        'SELECT * FROM tasks WHERE "userId" = @userId',
        substitutionValues: {
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
    isSameDate(DateTime.now(), task['date']) &&
        (userId!.trim()) == (task['userId']).toString()).toList();

    final substepResults = await connection.query('SELECT * FROM substeps');
    List<Map<String, dynamic>> substeps = substepResults.map((row) {
      return {
        'id': row[0],
        'status': row[4],
        'taskId': row[3],
      };
    }).toList();

    final substep = substeps.where((substep1) => substep1['taskId'] == _taskId).toList();

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
      }).where((task) => (userId!.trim()) == (task['userId']).toString() && task['status'] == 2).toList();

      int completedTasks = tasksCompleted.length;
      if (completedTasks % 5 == 0 && completedTasks >= 5) {
        String badgeLevel = '';
        if (completedTasks <= 30 && completedTasks >= 5) {
          badgeLevel = 'bronze${completedTasks ~/ 5}';
        } else if (completedTasks <= 60 && completedTasks > 30) {
          badgeLevel = 'silver${(completedTasks - 30) ~/ 10}';
        } else if (completedTasks <= 90 && completedTasks > 60) {
          badgeLevel = 'gold${(completedTasks - 60) ~/ 15}';
        } else if (completedTasks > 90 && completedTasks <= 180) {
          badgeLevel = 'platinum${(completedTasks - 90) ~/ 20}';
        }
        showBadgeAlert(badgeLevel);
      }
      widget.finishTask();
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

    await _getSubsets();
    await connection.close();
    _showConfetti();
    _currentMessageIndex=(prefs.getInt('message'))==null?0:prefs.getInt('message')!;
    final snackBar = SnackBar(
      content: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: Colors.green, width: 5),
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Text(
          _messages[_currentMessageIndex],
          style: TextStyle(color: Colors.black),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(bottom: 50, left: 10, right: 10),
      duration: Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    setState(() {
      _currentMessageIndex = (_currentMessageIndex + 1) % _messages.length;
      prefs.setInt('message', _currentMessageIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          key: ValueKey<int>(_id),
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _id != widget.firstnot1 ? (_status == 1 ? const Color(0xff00b386) : Colors.grey) : Colors.blue,
              width: 3.3,
            ),
            color: _status == 1 ? const Color(0xffe6fff5) : Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor:  _id != widget.firstnot1 ? (_status == 1 ? const Color(0xff00b386) : Colors.grey) : Colors.blue,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: _status == 1 ? const Color(0xff00b386) : Colors.white,
                    child: _status == 1
                        ? const Icon(Icons.check, color: Colors.white)
                        : Text(_id.toString(), style: const TextStyle(color: Colors.black)),                  ),
                ),

                SizedBox(width: MediaQuery.of(context).size.width * 0.08 + 16),
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
                    backgroundColor: _id != widget.firstnot1
                        ? (_status == 1 ? const Color(0xff00b386) : Colors.white)
                        : Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  ),
                  onPressed: () async {
                    if (_id == widget.firstnot1) {
                      await _finishSubstep();
                      setState(() {
                        _status = 1;
                        _refreshTasks();
                      });
                    }
                  },
                  child: _id == widget.firstnot1 && _status != 1
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
        ),
      ],
    );
  }
}
