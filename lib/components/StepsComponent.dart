import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:postgres/postgres.dart';

class StepsComponent extends StatefulWidget {
  final int taskId;
  final Function onLastStepComplete;

  StepsComponent({required this.taskId, required this.onLastStepComplete});

  @override
  _StepsComponentState createState() => _StepsComponentState();
}

class _StepsComponentState extends State<StepsComponent> {
  int currentStep = 0;
  List<dynamic> steps = [];

  @override
  void initState() {
    super.initState();
    fetchSubsteps(widget.taskId);
  }

  Future<void> fetchSubsteps(int taskId) async {
    final connection = PostgreSQLConnection(
      '${dotenv.env['DB_HOST']}',
      int.parse('${dotenv.env['DB_PORT']}'),
      '${dotenv.env['DB_DATABASE']}',
      username: '${dotenv.env['DB_USER']}',
      password: '${dotenv.env['DB_PASSWORD']}',
    );

    await connection.open();
    final results = await connection.query('SELECT * FROM substeps WHERE taskId = @taskId ORDER BY id ASC',
        substitutionValues: {'taskId': taskId});

    List<dynamic> substeps = [];
    for (var row in results) {
      substeps.add(row);
    }

    // Find the index of the first step with status 0
    int firstIncompleteStepIndex = substeps.indexWhere((step) => step['status'] == 0);

    // Set the current step to the index of the first incomplete step + 1
    setState(() {
      currentStep = firstIncompleteStepIndex + 1;
      steps = substeps;
    });

    await connection.close();
  }


  Future<void> updateTaskStatus(int taskId, int status) async {
    final connection = PostgreSQLConnection(
      '${dotenv.env['DB_HOST']}',
      int.parse('${dotenv.env['DB_PORT']}'),
      '${dotenv.env['DB_DATABASE']}',
      username: '${dotenv.env['DB_USER']}',
      password: '${dotenv.env['DB_PASSWORD']}',
    );

    await connection.open();
    // Get the current timestamp
    String userEndTime = DateTime.now().toIso8601String();

    await connection.execute(
      'UPDATE tasks SET status = @status, endTime = @userEndTime WHERE id = @taskId',
      substitutionValues: {'status': status, 'userEndTime': userEndTime, 'taskId': taskId},
    );
    await connection.close();
  }


  Future<void> updateTaskProgress(int taskId) async {
    final connection = PostgreSQLConnection(
      '${dotenv.env['DB_HOST']}',
      int.parse('${dotenv.env['DB_PORT']}'),
      '${dotenv.env['DB_DATABASE']}',
      username: '${dotenv.env['DB_USER']}',
      password: '${dotenv.env['DB_PASSWORD']}',
    );

    await connection.open();
    try {
      var completedSteps = steps.where((step) => step['status'] == 1).toList();
      double progress = ((completedSteps.length + 1) / steps.length) * 100;

      await connection.execute(
        'UPDATE tasks SET progress = @progress WHERE id = @taskId',
        substitutionValues: {'progress': progress, 'taskId': taskId},
      );
    } catch (error) {
      print('Error updating task progress: $error');
    }
    await connection.close();
  }

  Future<void> updateStepStatus(int stepId) async {
    final connection = PostgreSQLConnection(
      '${dotenv.env['DB_HOST']}',
      int.parse('${dotenv.env['DB_PORT']}'),
      '${dotenv.env['DB_DATABASE']}',
      username: '${dotenv.env['DB_USER']}',
      password: '${dotenv.env['DB_PASSWORD']}',
    );

    await connection.open();
    try {
      var response = await connection.query(
        'UPDATE substeps SET status = 1 WHERE id = @stepId',
        substitutionValues: {'stepId': stepId},
      );

      if (response != null && response.length > 0) {
        var updatedSteps = steps.map((step) {
          if (step['id'] == stepId) {
            return {...step, 'status': 1};
          }
          return step;
        }).toList();
        setState(() {
          steps = updatedSteps;
        });
        await updateTaskProgress(widget.taskId);
        // Check if all steps are completed
        bool allStepsCompleted = updatedSteps.every((step) => step['status'] == 1);
        if (allStepsCompleted) {
          // Update the task status to 2
          await updateTaskStatus(widget.taskId, 2);
          // Trigger the callback function in the Task component
          widget.onLastStepComplete();
        }
      }
    } catch (error) {
      print('Error updating step status: $error');
    }
    await connection.close();
  }


  void handleStepCompletion() {
    int currentStepId = steps[currentStep - 1]['id'];
    if (currentStepId != null) {
      updateStepStatus(currentStepId);
      setState(() {
        currentStep += 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: steps.length,
        itemBuilder: (BuildContext context, int index) {
          return renderStepCard(index + 1, steps[index]['stepName'], steps[index]['description'], index, steps[index]['status']);
        },
      ),
    );
  }

  Widget renderStepCard(int stepNumber, String stepName, String stepDescription, int index, int stepStatus) {
    bool isCurrentStep = currentStep == stepNumber;
    bool isCompletedStep = stepStatus == 1;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey),
        color: isCompletedStep ? Colors.lightGreenAccent : Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey),
              color: isCompletedStep ? Colors.lightGreen : Colors.white,
            ),
            child: Center(
              child: isCompletedStep ? Icon(Icons.check, color: Colors.white) : Text('$stepNumber'),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stepName,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isCompletedStep ? Colors.lightGreen : Colors.black),
                ),
                SizedBox(height: 5),
                Text(stepDescription, style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          SizedBox(width: 10),
          renderStepButton(stepNumber, stepStatus),
        ],
      ),
    );
  }

  Widget renderStepButton(int stepNumber, int stepStatus) {
    bool isCurrentStep = currentStep == stepNumber;
    bool isCompletedStep = stepStatus == 1;

    String buttonText = isCompletedStep ? 'Završeno' : (isCurrentStep ? 'Dalje' : 'Locked');
    Color buttonColor = isCompletedStep ? Colors.green : (isCurrentStep ? Colors.blue : Colors.grey);

    return TextButton(
      onPressed: isCurrentStep ? handleStepCompletion : null,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(buttonColor),
        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.symmetric(vertical: 10, horizontal: 20)),
      ),
      child: Text(
        buttonText,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
