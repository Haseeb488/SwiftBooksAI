import 'package:flutter/material.dart';

//details for client
String firstName = "";
String middleName = "";
String lastName = "";
String businessName = "";
String postCode = "";
String address = "";
String clientEmail = "";
String clientContact = "";
String password = "";
String clientID = "";
String phoneNumber = "";

// ---- details for Accountant

String accountantID = "";
String accountantName = "";
String accountantEmail = "";
String accountantPhone = "";

void showCircularProgress(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Center(child: CircularProgressIndicator(color: Colors.blue));
    },
  );
}

void hideCircularProgress(BuildContext context) {
  Navigator.pop(context);
}
