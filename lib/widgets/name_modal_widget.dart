import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mykoku_attendance/utils/custom_dialog.dart';

class NameModalWidget extends StatefulWidget {
  const NameModalWidget({super.key, this.image});

  final XFile? image;

  @override
  State<NameModalWidget> createState() => _NameModalWidgetState();
}

class _NameModalWidgetState extends State<NameModalWidget> {
  CustomDialog customDialog = CustomDialog();
  String? name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Face Embedding'),
      ),
      body: Column(
        children: [
          if (widget.image != null)
            Image.file(
              File(widget.image!.path),
              height: 200,
            ),
          Text('Name:'),
          TextField(
            onChanged: (value) {
              setState(() {
                name = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Enter your name',
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: ElevatedButton(
          onPressed: () async {
            customDialog.snackbarMessage(
              context,
              'Face embedding created for $name',
            );
            Navigator.pop(context, name);
          },
          child: Text('Create'),
        ),
      ),
    );
  }
}
