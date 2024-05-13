import 'package:flutter/material.dart';

class AvatarPicker extends StatefulWidget {
  final List<Map<String, dynamic>> avatars;
  final Function(Map<String, dynamic>) onSelectAvatar;

  AvatarPicker({required this.avatars, required this.onSelectAvatar});

  @override
  _AvatarPickerState createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  late Map<String, dynamic> selectedAvatar;

  @override
  void initState() {
    super.initState();
    selectedAvatar = widget.avatars[0];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.avatars.length,
        itemBuilder: (BuildContext context, int index) {
          final avatar = widget.avatars[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedAvatar = avatar;
              });
              widget.onSelectAvatar(avatar);
            },
            child: Container(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedAvatar == avatar ? Colors.blue : Colors.grey,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                backgroundImage: NetworkImage(avatar['url']),
                radius: 30,
              ),
            ),
          );
        },
      ),
    );
  }
}


