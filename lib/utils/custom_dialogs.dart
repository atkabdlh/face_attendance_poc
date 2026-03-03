import 'package:flutter/material.dart';
import 'package:mykoku_attendance/utils/debouncer.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomDialogs {
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

  // Future<void> snackbarAction(BuildContext context, String message,
  //     {int? milliseconds}) async {
  //   Debouncer(milliseconds: milliseconds ?? 100).run(() {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               message,
  //               style: GoogleFonts.roboto(
  //                 color: Colors.white,
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //             Text(
  //               'Slide to dissmiss',
  //               style: GoogleFonts.roboto(
  //                 color: Colors.white.withOpacity(0.8),
  //                 fontSize: 10,
  //                 fontWeight: FontWeight.w400,
  //               ),
  //             ),
  //           ],
  //         ),
  //         dismissDirection: DismissDirection.horizontal,
  //         action: SnackBarAction(
  //           label: 'Report',
  //           textColor: Colors.red[300]?.withOpacity(0.8),
  //           onPressed: () {
  //             BuildContext ancestorContext = context;
  //             Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                     builder: (context) => UserReport(
  //                           ancestorContext: ancestorContext,
  //                           snackbarMessage: message,
  //                         )));
  //           },
  //         ),
  //       ),
  //     );
  //   });
  // }
}
