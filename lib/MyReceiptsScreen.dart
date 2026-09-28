import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:swiftbook_ai/Global.dart';
import 'ReceiptImageViewerScreen.dart';

class MyReceiptsScreen extends StatefulWidget {
  const MyReceiptsScreen({super.key});

  @override
  State<MyReceiptsScreen> createState() => _MyReceiptsScreenState();
}

class _MyReceiptsScreenState extends State<MyReceiptsScreen> {
  List<Map<String, dynamic>> receipts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getReceiptDetails();
  }
  Future<void> getReceiptDetails() async {
    try {
      final response = await http.post(
        Uri.parse(
          "https://securenet.justyes.co.uk/Prod/SwiftBooksApis/receiptsJson.php",
        ),
        body: {
          "db_key": "R.kieZ",
          "clientID": clientID.toString(),

        },
      );

      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          setState(() {
            receipts = data
                .where(
                  (receipt) =>
              receipt["ClientID"].toString() == clientID.toString(),
            )
                .map<Map<String, dynamic>>(
                  (receipt) => Map<String, dynamic>.from(receipt),
            )
                .toList();

            isLoading = false;
          });
        } else {
          Fluttertoast.showToast(msg: "Invalid response from server");
          setState(() {
            isLoading = false;
          });
        }
      } else {
        Fluttertoast.showToast(
          msg: "Server Error: ${response.statusCode}",
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      // Fluttertoast.showToast(msg: "Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Receipts")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color:  Colors.blue,))
          : receipts.isEmpty
          ? const Center(child: Text("No receipts found",
      style: TextStyle(
        fontSize: 17
      ),))
          : ListView.builder(
              itemCount: receipts.length,
              itemBuilder: (context, index) {
                final receipt = receipts[index];
                return Card(
                  color: const Color.fromARGB(40, 158, 158, 158),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Issued By: ${receipt['ReceiptIssuedBy']}",
                          style: GoogleFonts.raleway(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),

                        Text("Customer ID: ${receipt['ClientID']}",
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                        ),
                        Text("Date: ${receipt['ReceiptDate']}",
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),),
                        Text("Time: ${receipt['ReceiptTime']}",
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),),
                        Text("Transaction Type: ${receipt['TransactionType']}",
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),),
                        Text("Total Amount: £${receipt['AmountTotal']}",
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),

                        ),

                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                            onPressed: () {
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReceiptImageViewerScreen(
                                    imageUrls: receipt['ImagePath'] + receipt['ImageNames'], // <-- updated
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),

                              backgroundColor: Colors.blue.shade600,
                            ),
                            child: const Text(
                              "View Receipt",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
