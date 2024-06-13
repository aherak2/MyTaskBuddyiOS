import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:diplomski/components/SubstepCard.dart';
import 'package:diplomski/components/StepsComponent.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:postgres/postgres.dart';
import 'package:confetti/confetti.dart';
import 'package:diplomski/components/background_service.dart';
class Task extends StatefulWidget {
  final Map<String, dynamic> route;
  final Function refreshTasks;

  Task({required this.route, required this.refreshTasks});

  @override
  _TaskState createState() => _TaskState(
    route: route,
  );
}

class _TaskState extends State<Task> with TickerProviderStateMixin {
  late String activityName;
  late DateTime date;
  late String startTime;
  late String endTime;
  late String location;
  late int parentId;
  late String firstName;
  late int status;
  late int firstNotCompleted;
  late bool isWhiteContainerVisible = true;
  late bool modalVisible = false;
  late bool congratsVisible = false;
  late bool animateEmoji2 = false;
  late int taskId;
  late List<Map<String, dynamic>>? subsets = [];
  late AnimationController slideAnimationController;
  late AnimationController slideUpAnimationController;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  late ConfettiController _confettiController;

  late String parentName='';
  _TaskState({required Map<String, dynamic> route}) {
    taskId = route['taskId'];
    activityName = route['activityName'];
    date = route['date'];
    startTime = route['startTime'];
    endTime = route['endTime'];
    location = route['location'];
    parentId = route['parentId'];
    firstName = route['firstName'];
    status = route['status'];
    parentName='';
  }

  @override
  void initState() {
    super.initState();
    parentNameFunction();
    if(status==0){
      setState(() {
        isWhiteContainerVisible=true;
      });    }
    if(status==1){
      setState(() {
        isWhiteContainerVisible=false;
      });
      }
    if(status==2) {
      setState(() {
        congratsVisible=true;
        isWhiteContainerVisible=false;
      });
    }
    slideAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 1000));
    slideUpAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    fetchSubsets();
  }
void finishedTask(){
    animateEmoji2=true;
}
  Widget singularCard(task,firstnot1) {
    return SubsetCard(
      status: task?['status'],
      taskId: task?['taskId'],
      stepName: task?['stepName'],
      id: task?['id'],
      description: task?['description'],
      getSubsets: getSubsets,
      refreshListView: refreshListView,
      refreshTasks: () {
        setState(() {
          isWhiteContainerVisible = true;
        });
        Future.delayed(Duration(milliseconds: 300), () {
          setState(() {
            fetchSubsets();
            isWhiteContainerVisible = false;
          });
        });
      },
      finishTask:finishedTask,
      firstnot1:firstnot1,
      subsets: subsets,
      showConfetti:_showConfetti,
      confettiController: _confettiController,
    );
  }Future<void> updateTask() async {
    final connection = PostgreSQLConnection(
      '${dotenv.env['DB_HOST']}',
      int.parse('${dotenv.env['DB_PORT']}'),
      '${dotenv.env['DB_DATABASE']}',
      username: '${dotenv.env['DB_USER']}',
      password: '${dotenv.env['DB_PASSWORD']}',
    );

    try {
      await connection.open();
      final substepResults = await connection.query('SELECT * FROM substeps');
      List<Map<String, dynamic>> substeps = substepResults.map((row) {
        return {
          'id': row[0],
          'status': row[4],
          'taskId': row[3],
        };
      }).toList();

      final substep = substeps.where((substep1) => substep1['taskId'] == taskId).toList();

      int completedSubsteps = substep.where((s) => s['status'] == 1).length;
      int totalSubsteps = substep.length;
      int progress=0;
      if (totalSubsteps == 0) {
progress=0;
      }
else
       progress = ((completedSubsteps / totalSubsteps) * 100).round();

      await connection.execute('''
      UPDATE tasks 
      SET status = 1, progress = @progress
      WHERE id = @id
    ''', substitutionValues: {
        'id': taskId,
        'progress': progress,
      });
    } catch (e) {
      // Handle any errors
      print('Error updating task: $e');
    } finally {
      await connection.close();
    }
  }

  Widget buildSubsetsListView() {
    return Column(
      children: subsets?.map((task) {
        return singularCard(task,firstNotCompleted);
      }).toList() ?? [],
    );
  }

Future<String> parentNameFunction() async {
    String name='';
    final connection = PostgreSQLConnection(
      '${dotenv.env['DB_HOST']}',
      int.parse('${dotenv.env['DB_PORT']}'),
      '${dotenv.env['DB_DATABASE']}',
      username: '${dotenv.env['DB_USER']}',
      password: '${dotenv.env['DB_PASSWORD']}',
    );

    await connection.open();
    final parentResult = await connection.query('SELECT firstname, lastname FROM parents WHERE id = @id', substitutionValues: {'id': parentId});
    connection.close();

    if (parentResult.isNotEmpty) {
      final row = parentResult.first;
      name = '${row[0]} ${row[1]}';
    }
setState(() {
  parentName=name;
});
    return name;
}

  Future<void> fetchSubsets() async {
    final result = await getSubsets();
    result.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
    setState(() {
      try {
        final firstSubsetWithStatus0 = result.firstWhere((subset) => subset['status'] == 0);
        firstNotCompleted = firstSubsetWithStatus0['id'];
      } catch (e) {
        firstNotCompleted = 0;
      }
      subsets = result;
    });
  }


  @override
  void dispose() {
    slideAnimationController.dispose();
    slideUpAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }



  void _showConfetti() {
    _confettiController.play();
  }
  Future<List<Map<String, dynamic>>> getSubsets() async {
    final connection = PostgreSQLConnection(
      '${dotenv.env['DB_HOST']}',
      int.parse('${dotenv.env['DB_PORT']}'),
      '${dotenv.env['DB_DATABASE']}',
      username: '${dotenv.env['DB_USER']}',
      password: '${dotenv.env['DB_PASSWORD']}',
    );

    await connection.open();
    final subsetResults = await connection.query('SELECT * FROM substeps ORDER BY id ASC');
    connection.close();

    var subset = subsetResults.map((row) {
      return {
        'id': row[0],
        'stepName': row[1],
        'description': row[2],
        'taskId': row[3],
        'status': row[4]
      };
    }).toList();
    subset = subset.where((item) => item['taskId'] == taskId).toList();

    return subset;
  }
String dateIspis(DateTime dateTime){
  String formattedDate = DateFormat.EEEE('bs').format(date);
  String formattedFullDate = DateFormat('dd. MMMM yyyy', 'bs').format(date);

  return formattedDate+ " "+formattedFullDate;
}
  void handleImagePress() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
      return AlertDialog(
          title: Center(
          child: Text(
          activityName.toString(),
    style: TextStyle(
    fontWeight: FontWeight.bold,
    ),
    textAlign: TextAlign.center,
    ),
    ),
    content: Container(
    padding: EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
    Row(
    children: [
    Image.asset(
    'assets/schedule.png',
    width: 20.0,
    height: 20.0,
    ),
    SizedBox(width: 10.0),
    Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    'Datum:',
    style: TextStyle(fontWeight: FontWeight.bold),
    ),
    Text(
    dateIspis(date),
    style: TextStyle(fontWeight: FontWeight.normal),
    ),
    ],
    ),
    ],
    ),
    SizedBox(height: 10.0),
    Row(
    children: [
    Image.asset(
    'assets/clock.png',
    width: 20.0,
    height: 20.0,
    ),
    SizedBox(width: 10.0),
    Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    'Trajanje:',
    style: TextStyle(fontWeight: FontWeight.bold),
    ),
    Text(
    '$startTime - $endTime',
    style: TextStyle(fontWeight: FontWeight.normal),
    ),
    ],
    ),
    ],
    ),
    SizedBox(height: 10.0),
    Row(
    children: [
    Image.asset(
    'assets/placeholder.png',
    width: 20.0,
    height: 20.0,
    ),
    SizedBox(width: 10.0),
    Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text(
    'Lokacija:',
    style: TextStyle(fontWeight: FontWeight.bold),
    ),
    Text(
    location,
    style: TextStyle(fontWeight: FontWeight.normal),
    ),
    ],
    ),
    ],
    ),
    SizedBox(height: 10.0),
    Row(
    children: [
    Image.asset(
    'assets/ancestors.png',
    width: 20.0,
    height: 20.0,
    ),
    SizedBox(width: 10.0),
    Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text(
    'Zadatak zadao/la:',
    style: TextStyle(fontWeight: FontWeight.bold),
    ),
    Text(
    parentName,
    style: TextStyle(fontWeight:
    FontWeight.normal),
    ),
    ],
    ),
    ],
    ),
      SizedBox(height: 20.0),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  side: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.all(10),
              ),
              alignment: Alignment.center,
            ),
            child: Text(
              'Close',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: MediaQuery.of(context).size.width * 0.033,
              ),
            ),
          ),
        ],
      ),
    ],
    ),
    ),
      );
        },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () {
            widget.refreshTasks();
            Navigator.pop(context);
          },
          child: Image.asset('assets/left.png'),
        ),
        actions: [
          GestureDetector(
            onTap: () => handleImagePress(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/detail.png'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      maxBlastForce: 5,
                      minBlastForce: 2,
                      emissionFrequency: 0.05,
                      numberOfParticles: 20,
                      gravity: 0.05,
                    ),
                  ),
                ],),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 500),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: congratsVisible
                        ? Image.asset('assets/checklist.png', width: MediaQuery.of(context).size.width * 0.2, key: ValueKey('checklist'))
                        : (animateEmoji2
                        ? Image.asset('assets/emoji2.png', width: MediaQuery.of(context).size.width * 0.4, key: ValueKey('emoji2'))
                        : Image.asset('assets/planning2.png', width: MediaQuery.of(context).size.width * 0.2, key: ValueKey('planning2'))),
                  ),
                  Text(
                    congratsVisible ? "Završen zadatak" : (animateEmoji2 ? "Bravo, uspješno ste obavili zadatak" : "Zdravo $firstName, idemo raditi zadatak"),
                    style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035, color: Colors.grey),
                  ),
                  Text(activityName, style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.06, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (isWhiteContainerVisible)
              ElevatedButton(
                onPressed: () {
                  updateTask();

                  setState(() {
                    isWhiteContainerVisible = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.shade200,
                ),
                child: Text(
                  'Započni',style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
                ),
              ),
            SizedBox(height: 20),
            AnimatedOpacity(
              opacity: isWhiteContainerVisible ? 0.0 : 1.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: buildSubsetsListView(),
            ),    ],
        ),
      ),

    );
  }


  void refreshTasks() {
    _listKey.currentState?.setState(() {});
  }

  void rebuildAllChildren(BuildContext context) {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }
    (context as Element).visitChildren(rebuild);
  }

  void refreshListView() {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }
}