import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mykoku_attendance/utils/debouncer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mykoku_attendance/widgets/name_modal_widget.dart';

enum DialogSize { small, medium, large, custom }

class CustomDialog {
  Future<void> snackbarMessage(BuildContext context, String message,
      {int? milliseconds}) async {
    Debouncer(milliseconds: milliseconds ?? 100).run(() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Slide to dissmiss',
                style: GoogleFonts.roboto(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          dismissDirection: DismissDirection.horizontal,
        ),
      );
    });
  }

  Future<void> snackbarAction(BuildContext context, String message,
      {int? milliseconds}) async {
    Debouncer(milliseconds: milliseconds ?? 100).run(() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Slide to dissmiss',
                style: GoogleFonts.roboto(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          dismissDirection: DismissDirection.horizontal,
          action: SnackBarAction(
            label: 'Report',
            textColor: Colors.red[300]?.withOpacity(0.8),
            onPressed: () {
              BuildContext ancestorContext = context;
              print('Report pressed');
              // Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //         builder: (context) => UserReport(
              //               ancestorContext: ancestorContext,
              //               snackbarMessage: message,
              //             )));
            },
          ),
        ),
      );
    });
  }

  Future<void> bottomSheetDialog(
      BuildContext context, String title, Widget content, DialogSize modalSize,
      {double? heightFactor}) async {
    double height = 0.6;
    if (modalSize == DialogSize.custom) {
      height = heightFactor ?? 0.6;
    } else {
      switch (modalSize) {
        case DialogSize.small:
          height = 0.3;
          break;
        case DialogSize.medium:
          height = 0.6;
          break;
        case DialogSize.large:
          height = 0.8;
          break;
        case DialogSize.custom:
          break;
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          topLeft: Radius.circular(24),
        ),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: height,
          child: Scaffold(
            appBar: AppBar(
              title: Text(title),
            ),
            body: content,
          ),
        );
      },
    );
  }

  Future<String?> nameModalDialog(BuildContext context, XFile? file) async {
    String? name = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          topLeft: Radius.circular(24),
        ),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.6,
          child: NameModalWidget(image: file),
        );
      },
    );

    return name;
  }
}
