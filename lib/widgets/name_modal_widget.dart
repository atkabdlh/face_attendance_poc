import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:face_attendance_poc/utils/custom_dialog.dart';

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (widget.image != null)
                Image.file(
                  File(widget.image!.path),
                  height: 200,
                ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Name:'),
              ),
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
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton(
                  onPressed: () async {
                    customDialog.snackbarMessage(
                      context,
                      'Face embedding created for $name',
                    );
                    Navigator.pop(context, name);
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Center(child: Text('Create')),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }
}
