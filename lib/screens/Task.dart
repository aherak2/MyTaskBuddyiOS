import 'package:diplomski/components/SubstepCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:diplomski/components/StepsComponent.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/widgets.dart';
import 'package:postgres/postgres.dart';
class Task extends StatefulWidget {
  final Map<String, dynamic> route;
  final Function refreshTasks;


  Task({required this.route,required this.refreshTasks});

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
  late bool isWhiteContainerVisible=true;
  late bool modalVisible=false;
  late bool congratsVisible=false;
  late bool animateEmoji2=false;
  late int taskId;
  late List<Map<String, dynamic>>? subsets=[];
  late AnimationController slideAnimationController;
  late AnimationController slideUpAnimationController;

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
  }

  @override
  void initState() {
    super.initState();
    slideAnimationController = AnimationController(vsync: this, duration: Duration(milliseconds: 1000));
    slideUpAnimationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    fetchSubsets();
  }


  Future<void> fetchSubsets() async {
    final result = await getSubsets();
    result.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

    setState(() {
      try {
      final  firstSubsetWithStatus0 = result.firstWhere((subset) => subset['status'] == 0);
      firstNotCompleted = firstSubsetWithStatus0['id'];

      } catch (e) {
        firstNotCompleted=0;
      }
      subsets = result;
    });
  }

  @override
  void dispose() {
    slideAnimationController.dispose();
    slideUpAnimationController.dispose();
    super.dispose();
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
    final subsetResults = await connection.query('SELECT * FROM substeps');
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Image.asset('assets/schedule.png', width: 20.0, height: 20.0),
                    SizedBox(width: 10.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Datum:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          date.toString(),
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10.0),
                Row(
                  children: [
                    Image.asset('assets/clock.png', width: 20.0, height: 20.0),
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
                    Image.asset('assets/placeholder.png', width: 20.0, height: 20.0),
                    SizedBox(width: 10.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
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
                    Image.asset('assets/ancestors.png', width: 20.0, height: 20.0),
                    SizedBox(width: 10.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Zadatak zadao/la:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$parentId',
                          style: TextStyle(fontWeight: FontWeight.normal),
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
                        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.all(10)),
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
      body: Container(
        constraints: BoxConstraints.expand(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            animateEmoji2
                ? AnimatedContainer(
              alignment: Alignment.center,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              transform: Matrix4.translationValues(0, animateEmoji2 ? 0 : -200, 0),
              child: Column(
                children: [
                  Image.asset('assets/emoji2.png', width: MediaQuery.of(context).size.width * 0.2),
                  Text('Bravo, uspješno ste obavili zadatak', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035, color: Colors.grey)),
                  Text(activityName, style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.06, fontWeight: FontWeight.bold)),
                ],
              ),
            )
                : Container(
              padding: EdgeInsets.only(top: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Image.asset(congratsVisible ? 'assets/checklist.png' : 'assets/planning2.png', width: MediaQuery.of(context).size.width * 0.2),
                  Text(
                    congratsVisible ? "Završen zadatak" : "Zdravo $firstName, idemo raditi zadatak",
                    style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035, color: Colors.grey),
                  ),
                  Text(activityName, style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.06, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            SizedBox(height: 10.0),
            Flexible(
              child: GestureDetector(
                onTap: () => startTask(),
                child: ListView.builder(
                  itemCount: subsets?.length,
                  itemBuilder: (context, index) {
                    final task = subsets?[index];
                    return SubsetCard(
                      status: task?['status'],
                      taskId: task?['taskId'],
                      stepName: task?['stepName'],
                      id: task?['id'],
                      description: task?['description'],
                      getSubsets:getSubsets,
                      refreshListView: refreshListView,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void refreshListView() {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      setState(() {});
    });  }

  void startTask() {
  }
}
