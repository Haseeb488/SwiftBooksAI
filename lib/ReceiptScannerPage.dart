import 'dart:convert';
import 'dart:io';
import 'package:edge_alerts/edge_alerts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'DashBoard.dart';
import 'Global.dart';
import 'ProfessionalProgressDialog.dart';
import 'main.dart';

class ReceiptScannerPage extends StatefulWidget {
  final List<File> imageFile;
  final String imageNames;
  final String receiptType;

  ReceiptScannerPage({
    Key? key,
    required this.imageFile,
    required this.imageNames,
    required this.receiptType,
  }) : super(key: key);

  @override
  _ReceiptScannerPageState createState() => _ReceiptScannerPageState();
}

class _ReceiptScannerPageState extends State<ReceiptScannerPage> {
  String submitButtonTitle = "Submit Invoice";

  int nameListIndex = 0;

  int upperImageIndex = 0;

  // Split the string into a List of individual file names
  late List<String> nameList = widget.imageNames.split(',');

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.receiptType == "Bulk") {
        setState(() {
          submitButtonTitle = "Scan Next Invoice";
        });
      }

      if (widget.imageFile.isNotEmpty) {
        // print("📷 INITIAL TOTAL IMAGES PASSED: ${widget.imageFile.length}");
        // print("📷 TOTAL IMAGES PASSED: ${widget.imageFile.toString()}");

        // 1. Process the very first image automatically
        _processImage([widget.imageFile[0]]);

        // 2. Set index to 1, ready for the next button click
        nameListIndex = 1;
        upperImageIndex = 0;
      }
    });
    Image.file(
      widget.imageFile[nameListIndex], // Dynamic preview update!
      height: 200,
      fit: BoxFit.cover,
    );
  }

  String _extractedTotal = '';
  List<String> _suggestedTotals = [];
  bool _isProcessing = false;
  bool fieldsVisibility = false;

  String? _extractedDate;


  List<String> types = ["Income", "Expense", "Purchase"];
  String? selectedTransactionType;

  String? selectedVAT;

  List<String> vatOptions = ["Yes", "No"];

  bool isDarkMode = themeNotifier.value == ThemeMode.dark;

  final TextEditingController totalInvoiceController = TextEditingController();
  final TextEditingController receiptIssuedByController =
      TextEditingController();
  final TextEditingController receiptCategoryController =
      TextEditingController();
  final TextEditingController receiptDateController = TextEditingController();

  final TextEditingController referenceController = TextEditingController();
  final TextEditingController vatAmountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool vatAmountVisibility = false;

  String? currentReceiptId;

  String startTime = "";
  String endTime = "";
  String responseTime = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.blue, // Drawer icon color
        ),
        title: Text(
          '',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 250,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: widget.imageFile.isNotEmpty
                        ? Image.file(
                            // Safely access current image, clamped to valid list range
                            widget.imageFile[upperImageIndex <
                                    widget.imageFile.length
                                ? upperImageIndex
                                : widget.imageFile.length - 1],
                            height: 200,
                            fit: BoxFit.cover,
                          )
                        : const Center(child: Text('No preview available')),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_isProcessing)
                const CircularProgressIndicator()
              else ...[
                if (_extractedTotal.isNotEmpty)
                  InkWell(
                    onTap: () {
                      showTotalAmountEditDialog(context);
                    },
                    child: Card(
                      color: isDarkMode
                          ? Color.fromARGB(40, 158, 158, 158)
                          : Colors.blue,

                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 14,
                          right: 14,
                          top: 10,
                          bottom: 10,
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              // Keeps the row compact
                              crossAxisAlignment: CrossAxisAlignment.center,
                              // Aligns text and icon vertically
                              children: [
                                Text(
                                  "£$_extractedTotal ",
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.white,
                                  ),
                                ),
                                Icon(
                                  Icons.edit,
                                  // Replace with your desired icon
                                  size: 24,
                                  // Matches the font size for visual balance
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.white,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_suggestedTotals.isNotEmpty) ...[
                  const SizedBox(height: 20),

                  TextField(
                    controller: receiptIssuedByController,
                    textInputAction: TextInputAction.next,
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Receipt Issued By*',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      // White label color
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.white,
                        ), // White border color
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white60 : Colors.black87,
                        ), // White border when enabled
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.blue,
                        ), // White border when focused
                      ),
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),

                  TextField(
                    controller: receiptCategoryController,
                    cursorColor: Colors.white,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Receipt Category*',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      // White label color
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.white,
                        ), // White border color
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white60 : Colors.black87,
                        ), // White border when enabled
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.blue,
                        ), // White border when focused
                      ),
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),

                  TextField(
                    controller: receiptDateController,
                    textInputAction: TextInputAction.next,
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Receipt Date*',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),

                      // White label color
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.white,
                        ), // White border color
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white60 : Colors.black87,
                        ), // White border when enabled
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.blue,
                        ), // White border when focused
                      ),
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],

                SizedBox(height: 16),
                // Description TextField
                Visibility(
                  visible: vatAmountVisibility,
                  child: TextField(
                    controller: vatAmountController,
                    cursorColor: Colors.white,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'VAT Amount*',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),

                      // White label color
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white60 : Colors.black87,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white60 : Colors.black87,
                        ), // White border when enabled
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.blue,
                        ), // White border when focused
                      ),
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),

                SizedBox(height: 16),
                Visibility(
                  visible: fieldsVisibility,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDarkMode ? Colors.white60 : Colors.black87,
                      ),
                      // Changed from grey to white
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedTransactionType,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        // White text for selected item
                        hint: Text(
                          "Select Transaction Type*",
                          style: TextStyle(
                            color: isDarkMode ? Colors.white60 : Colors.black87,
                          ), // White hint text
                        ),
                        isExpanded: true,
                        dropdownColor: isDarkMode ? Colors.black : Colors.white,
                        // Black dropdown menu background
                        items: types.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ), // White item text
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedTransactionType = newValue;
                          });
                        },
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white, // White dropdown icon
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                Visibility(
                  visible: fieldsVisibility,
                  child: TextField(
                    controller: referenceController,
                    cursorColor: Colors.white,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Reference or Invoice# (Optional)',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),

                      // White label color
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white60 : Colors.black87,
                        ), // White border color
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white60 : Colors.black87,
                        ), // White border when enabled
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.blue,
                        ), // White border when focused
                      ),
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),

                SizedBox(height: 16),
                Visibility(
                  visible: fieldsVisibility,
                  child: TextField(
                    controller: notesController,
                    textInputAction: TextInputAction.next,
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.white,
                        ), // White border color
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white60 : Colors.black87,
                        ), // White border when enabled
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white60 : Colors.black87,
                        ), // White border when focused
                      ),
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],

              SizedBox(height: 8),
              const SizedBox(height: 15),
              Visibility(
                visible: fieldsVisibility,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.payment, color: Colors.white),
                        label: Text(
                          submitButtonTitle,
                          style: TextStyle(color: Colors.white, fontSize: 15.0),
                        ),
                        onPressed: () async {
                          FocusScope.of(context).unfocus();

                          if (widget.receiptType == "Single") {
                            _uploadReceiptData();
                          } else {
                            //When Bulk Option is selected

                            FocusScope.of(context).unfocus();

                            // print("--- BUTTON CLICKED ---");
                            // print("Total images: ${widget.imageFile.length}");
                            // print("Current index to process: $nameListIndex");

                            if (nameListIndex <= widget.imageFile.length) {
                              // Pass the exact current file to your upload function
                              await _uploadReceiptData();
                            }
                            // 1. Update your button handler to pass the current file
                            if (nameListIndex < widget.imageFile.length) {
                              // Process visually

                              _processImage([widget.imageFile[nameListIndex]]);

                              // Move to the next index
                              setState(() {
                                nameListIndex++;
                                upperImageIndex++;
                              });
                            } else {
                              showSuccessDialog(context);
                            }
                          }

                          // here I have to call the function
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Colors.blue,
                          ), // Change this color
                          padding: MaterialStateProperty.all<EdgeInsets>(
                            EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ), // Optional: adjust padding
                          ),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    8.0,
                                  ), // Optional: rounded corners
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    receiptIssuedByController.dispose();
    receiptCategoryController.dispose();
    receiptDateController.dispose();
    referenceController.dispose();
    vatAmountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void showTotalAmountEditDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔶 Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color.fromARGB(40, 158, 158, 158),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Enter total amount',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // 📝 TextField
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: totalInvoiceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Total Amount',
                    hintText: 'e.g. £50',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),
              // 🔘 Buttons
              Column(
                children: [
                  SizedBox(
                    width: 150,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(40, 158, 158, 158),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        if (totalInvoiceController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please enter discount amount"),
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).pop();

                        setState(() {
                          _extractedTotal = totalInvoiceController.text;
                        });
                      },
                      child: const Text(
                        'Confirm',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("No"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: const Text("Yes"),
      onPressed: () {
        if (Platform.isAndroid) {
          SystemNavigator.pop();
        } else if (Platform.isIOS) {
          exit(0);
        }
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Log Out"),
      content: const Text("Are you sure to Logout  and exit the app?"),
      actions: [cancelButton, continueButton],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void showSuccessDialog(BuildContext context) {
    bool isDarkMode = themeNotifier.value == ThemeMode.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top green success section
              Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    Text(
                      'Invoice Submitted',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You have successfully submitted your invoice.',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Buttons section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => DashBoard()),
                        );
                      },
                      child: const Text(
                        'Submit Another Invoice',
                        style: TextStyle(color: Colors.green, fontSize: 16),
                      ),
                    ),

                    Divider(
                      color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        if (Platform.isAndroid) {
                          SystemNavigator.pop();
                        } else if (Platform.isIOS) {
                          exit(0);
                        }
                      },
                      child: const Text(
                        'Exit App',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /*
  Future<void> _uploadReceiptImage(File file, {bool isFirstPage = true}) async {
    try {
      showCircularProgress(context);

      const apiUrl =
          'https://securenet.justyes.co.uk/Prod/SwiftBooksApis/uploadImage.php';

      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      final encodedImage = base64Encode(await file.readAsBytes());
      final imageName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (isFirstPage) {
        // ✅ First page: send all details
        request.fields['ClientID'] = email;
        request.fields['clientName'] = name;
        request.fields['receiptIssuedBy'] = receiptIssuedByController.text;
        request.fields['categoryId'] = selectedCategory?.id ?? "";
        request.fields['receiptDate'] = receiptDateController.text;
        request.fields['receiptTime'] = receiptTimeController.text;
        request.fields['transactionType'] = selectedTransactionType.toString();
        request.fields['totalBill'] = _extractedTotal;
        request.fields['hasVAT'] = selectedVAT.toString();
        request.fields['vatAmount'] = vatAmountController.text;
        request.fields['reference'] = referenceController.text;
        request.fields['notes'] = notesController.text;
        request.fields['accountantID'] = accountantID;
      } else {
        // ✅ Extra pages: send only receiptID
        request.fields['receiptID'] = _receiptID ?? "";
      }

      // ✅ Common fields
      request.fields['encoded_string'] = encodedImage;
      request.fields['image_name'] = imageName;
      request.fields['fullPath'] =
          "https://securenet.justyes.co.uk/Prod/SwiftBooksApis/images/" +
              imageName;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final responseJson = json.decode(responseData);

      Navigator.pop(context); // close loading

      if (response.statusCode == 200 && responseJson['success'] == true) {
        if (isFirstPage) {
          // ✅ Store receiptID for subsequent pages
          _receiptID = responseJson['receiptID'];

          // showSuccessDialog(context);

          // Clear some fields for neatness
          receiptIssuedByController.clear();
          receiptDateController.clear();

        } else {
          // ✅ Ask user if they want to upload another page
          _askForMorePages();
        }
      } else {
        edgeAlert(
          context,
          title: 'Upload Failed',
          description: responseJson['message'] ?? 'Unknown error occurred',
          gravity: Gravity.bottom,
          duration: 10,
          icon: Icons.error,
        );
      }
    } catch (e) {
      Navigator.pop(context);
      edgeAlert(
        context,
        title: 'Error',
        description: e.toString(),
        gravity: Gravity.bottom,
        duration: 10,
        icon: Icons.error,
      );
    }
  }
*/

  Future<void> _uploadReceiptData() async {
    try {
      if (receiptIssuedByController.text.isEmpty) {
        edgeAlert(
          context,
          title: 'Receipt Title Required',
          description: 'Please enter the receipt issued by',
          gravity: Gravity.bottom,
          duration: 2,
          backgroundColor: Colors.blue,
          icon: Icons.error,
        );
        return;
      }

      if (receiptDateController.text.isEmpty) {
        edgeAlert(
          context,
          title: 'Date on receipt is required',
          description: 'Please enter the date on receipt',
          gravity: Gravity.bottom,
          duration: 2,
          backgroundColor: Colors.blue,
          icon: Icons.error,
        );
        return;
      }


      if (selectedTransactionType.toString() == "null") {
        edgeAlert(
          context,
          title: 'Transaction Type Required',
          description: 'Please select transaction type',
          gravity: Gravity.bottom,
          duration: 2,
          backgroundColor: Colors.blue,
          icon: Icons.error,
        );
        return;
      }

      showCircularProgress(context);
      const apiUrl =
          'https://securenet.justyes.co.uk/Prod/SwiftBooksApis/uploadReceiptData.php';

      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      request.fields['db_key'] = "R.kieZ";
      request.fields['clientID'] = clientID;
      request.fields['clientName'] = lastName;
      request.fields['receiptIssuedBy'] = receiptIssuedByController.text;
      request.fields['category'] = receiptCategoryController.text;
      request.fields['receiptDate'] = receiptDateController.text;
      request.fields['transactionType'] = selectedTransactionType.toString();
      request.fields['totalBill'] = _extractedTotal;
      request.fields['hasVAT'] = selectedVAT.toString();
      request.fields['vatAmount'] = vatAmountController.text;
      request.fields['imagePath'] = "https://securenet.justyes.co.uk/Prod/SwiftBooksApis/images/$clientID/";
      if (widget.receiptType == "Single") {
        request.fields['imageName'] = widget.imageNames;
      }
      if (widget.receiptType == "Bulk") {
        request.fields['imageName'] = nameList[nameListIndex - 1];
      }

      request.fields['reference'] = referenceController.text;
      request.fields['notes'] = notesController.text;
      request.fields['accountantID'] = accountantID;
      request.fields['apiCallingTime'] = startTime;
      request.fields['apiResponseTime'] = endTime;
      request.fields['totalDuration'] = responseTime;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final responseJson = json.decode(responseData);

      Navigator.pop(context); // close loader

      if (response.statusCode == 200 && responseJson['success'] == true) {
        if (widget.receiptType == "Single") showInvoiceSubmittedDialog(context);
      } else {
        edgeAlert(
          context,
          title: 'Upload Failed',
          description: responseJson['message'] ?? 'Unknown error',
          gravity: Gravity.bottom,
          duration: 10,
          icon: Icons.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      edgeAlert(
        context,
        title: 'Error',
        description: e.toString(),
        gravity: Gravity.bottom,
        duration: 10,
        icon: Icons.error,
      );
    }
  }

  void showApiErrorDialog(
    String errorDetail,
    BuildContext context, {
    VoidCallback? onDashboard,
  }) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      barrierDismissible: false,
      showCancelBtn: false,
      confirmBtnText: 'Try again',
      confirmBtnColor: const Color(0xFF4CAF50),
      title: 'Error Occurred',
      text: errorDetail,
      onConfirmBtnTap: () {
        Navigator.pop(context); // Close dialog
        _processImage(widget.imageFile);
      },
    );
  }

  void showInvoiceSubmittedDialog(
    BuildContext context, {
    VoidCallback? onDashboard,
  }) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      barrierDismissible: false,
      showCancelBtn: false,
      confirmBtnText: 'Go To Dashboard',
      confirmBtnColor: const Color(0xFF4CAF50),
      title: 'Invoice Submitted',
      text:
          'Thank you for choosing SwiftBooksAI. Your invoice has been submitted to your accountant.',
      onConfirmBtnTap: () {
        Navigator.pop(context); // Close dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashBoard()),
        );
      },
    );
  }


  Future<void> _processImage(List<File> imageFiles) async {
    // Show a loading indicator here if you have one

    showProgressDialog();

    try {
      startTime = getCurrentTime();

      // 1. Prepare the multipart request
      final url = Uri.parse(
        'https://securenet.justyes.co.uk/Prod/SwiftBooksApis/Qwen/receipt_ocr.php',
      );
      final request = http.MultipartRequest('POST', url);

      // 2. Loop through all images in the list and attach them to the request
      for (File imageFile in imageFiles) {
        final stream = http.ByteStream(imageFile.openRead());
        final length = await imageFile.length();

        final multipartFile = http.MultipartFile(
          'images[]', // Using array bracket format for your PHP foreach loop
          stream,
          length,
          filename: imageFile.path.split('/').last,
        );

        request.files.add(multipartFile);
      }

      // 3. Send the single request containing all attached images to your PHP backend
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        Navigator.pop(context);

        uploadApiError("Server returned status code ${response.statusCode}");

        showApiErrorDialog(
          "Server returned status code ${response.statusCode}",
          context,
        );
        throw Exception('Server returned status code ${response.statusCode}');
      }

      // 4. Parse the PHP API JSON response
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey('error')) {
        Navigator.pop(context);
        uploadApiError('API Error: ${data['error']}');
        showApiErrorDialog('API Error: ${data['error']}', context);
        throw Exception('API Error: ${data['error']}');
      }

      endTime = getCurrentTime();

      responseTime = calculateTimeDifference(startTime, endTime);

      // debugPrint("start Time: " + startTime);
      // debugPrint("End Time: " + endTime);
      // debugPrint("Response Time: " + responseTime);

      // 5. Extract values matching your PHP output structure
      final String guessedTitle = data['title'] ?? '';
      final double totalAmount = (data['total'] ?? 0.0).toDouble();
      final String category = (data['category']);
      final double vatAmount = (data['vat'] ?? 0.0).toDouble();
      final String? rawDate = data['date'];
      final String? extractedDate = formatDateToDDMMYYYY(rawDate);
      final String? extractedTime = data['time'];

      // Check VAT presence dynamically based on whether amount is greater than 0
      final String hasVat = vatAmount > 0 ? "Yes" : "No";

      // 6. Update UI state with the fresh AI-extracted data
      setState(() {
        Navigator.pop(context);

        vatAmountVisibility = true;

        _extractedTotal = totalAmount.toString();
        if (hasVat == "Yes") {
          selectedVAT = "Yes";
        } else {
          selectedVAT = "No";
        }
        _suggestedTotals = [totalAmount.toString()];
        vatAmountController.text = vatAmount.toString();
        receiptCategoryController.text = category;
        receiptIssuedByController.text = guessedTitle;
        _extractedDate = extractedDate ?? "";
        fieldsVisibility = true;
      });

      // Populate the controllers
      receiptDateController.text = _extractedDate!;

    } catch (e) {
      // Handle network or parsing errors elegantly here
      Navigator.pop(context);
      uploadApiError("Failed to process receipt via Qwen: $e");
      showApiErrorDialog('Failed to process receipt via Qwen: $e', context);
      debugPrint("Failed to process receipt via Qwen: $e");
      // Optionally alert the user with a SnackBar or Dialog
    }
  }

  String getCurrentTime() {
    final DateTime now = DateTime.now();
    return DateFormat('HH:mm:ss').format(now);
  }

  /// Calculates difference between two time strings formatted as "HH:mm:ss".
  String calculateTimeDifference(String startTimeStr, String endTimeStr) {
    final DateFormat format = DateFormat('HH:mm:ss');

    // Parse strings into DateTime objects (using today's date)
    final DateTime start = format.parse(startTimeStr);
    final DateTime end = format.parse(endTimeStr);

    // Calculate positive duration
    final Duration difference = end.difference(start).abs();

    final int minutes = difference.inMinutes;
    final int seconds = difference.inSeconds % 60;

    final String minStr = '$minutes ${minutes == 1 ? "min" : "mins"}';
    final String secStr = '$seconds ${seconds == 1 ? "sec" : "secs"}';

    return '$minStr $secStr';
  }

  String? formatDateToDDMMYYYY(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return null;

    DateTime? parsedDate;

    // 1. Try standard ISO 8601 parsing first (e.g., "2026-09-23", "2026-09-23T14:30:00")
    parsedDate = DateTime.tryParse(rawDate);

    // 2. If ISO fails, try matching common receipt date formats
    if (parsedDate == null) {
      final List<String> commonFormats = [
        'yyyy-MM-dd',
        'dd/MM/yyyy',
        'MM/dd/yyyy',
        'dd-MM-yyyy',
        'MM-dd-yyyy',
        'd MMM yyyy', // e.g., 23 Sep 2026
        'd MMMM yyyy', // e.g., 23 September 2026
        'MMM d, yyyy', // e.g., Sep 23, 2026
        'yyyy/MM/dd',
        'dd.MM.yyyy',
      ];

      for (String format in commonFormats) {
        try {
          parsedDate = DateFormat(format).parseStrict(rawDate.trim());
          break; // Successfully parsed
        } catch (_) {
          // Continue checking next format
        }
      }
    }

    // 3. Convert to dd/MM/yyyy format if parsing succeeded
    if (parsedDate != null) {
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    }

    // Return original text if parsing failed completely
    return rawDate;
  }

  // To show the dialog
  void showCircularProgress(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            color: Colors.blue, // Set the progress indicator color to blue
          ),
        );
      },
    );
  }

  void showProgressDialog() async {
    ProfessionalProgressDialog.show(context);

    // Perform async action (e.g., image API call)
    await Future.delayed(const Duration(seconds: 3));
    //
    // // To dismiss the progress dialog safely
    //     if (mounted) {
    //       ProfessionalProgressDialog.hide(context);
    //     }
  }

  Future uploadApiError(String errorMessage) async {
    try {
      var url = Uri.parse(
        "https://securenet.justyes.co.uk/Prod/SwiftBooksApis/apiErrors.php",
      );

      var response = await http.post(
        url,
        body: {
          "db_key": "R.kieZ",
          "userName": lastName,
          "date": getCurrentDate(),
          "time": getCurrentTime(),
          "error": errorMessage,
        },
      );

      if (response.statusCode == 200) {
        debugPrint("Response: ${response.body}");
        var data = json.decode(response.body);

        if (data == "SUCCESS") {
          Fluttertoast.showToast(msg: "Error uploaded");
        }
      }
    } catch (error) {
      Fluttertoast.showToast(msg: "Something went wrong");
      debugPrint("Error: $error");
    }
  }

  String getCurrentDate() {
    // 1. Get current Date
    DateTime now = DateTime.now();

    // 2. Format to dd/MM/yyyy
    String formattedDate = DateFormat('dd/MM/yyyy').format(now);

    return formattedDate;
  }

  String extractTotalAmount(String text) {
    final lines = text.split('\n');
    final totalKeywords = [
      'total',
      'grand total',
      'amount due',
      'balance',
      'amount payable',
    ];
    final ignoreKeywords = [
      'subtotal',
      'tax',
      'vat',
      'change',
      'tip',
      'rounding',
    ];
    final amountRegex = RegExp(r'(\$?\d{1,3}(?:[,.\s]?\d{3})*[.,]\d{2})');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].toLowerCase().replaceAll(RegExp(r'\s+'), '');

      if (totalKeywords.any((k) => line.contains(k.replaceAll(' ', '')))) {
        final match = amountRegex.firstMatch(lines[i]);
        if (match != null)
          return match.group(0)!.replaceAll(RegExp(r'[^\d.]'), '');

        if (i + 1 < lines.length) {
          final nextLineMatch = amountRegex.firstMatch(lines[i + 1]);
          if (nextLineMatch != null)
            return nextLineMatch.group(0)!.replaceAll(RegExp(r'[^\d.]'), '');
        }
      }
    }

    final matches = amountRegex.allMatches(text);
    double maxAmount = 0.0;

    for (final match in matches) {
      final amountStr = match.group(0)!.replaceAll(RegExp(r'[^\d.]'), '');
      final amount = double.tryParse(amountStr);
      if (amount == null) continue;

      final contextStart = (match.start - 15).clamp(0, text.length);
      final contextEnd = (match.end + 15).clamp(0, text.length);
      final context = text.substring(contextStart, contextEnd).toLowerCase();

      if (ignoreKeywords.any((kw) => context.contains(kw))) continue;

      if (amount > maxAmount) maxAmount = amount;
    }

    return maxAmount > 0 ? maxAmount.toStringAsFixed(2) : 'Total not found';
  }

  List<String> extractSuggestedTotals(String text) {
    final amountRegex = RegExp(r'(\$?\d{1,3}(?:[,.\s]?\d{3})*[.,]\d{2})');
    final ignoreKeywords = [
      'subtotal',
      'tax',
      'vat',
      'change',
      'tip',
      'rounding',
    ];
    final suggestions = <String>{};

    for (final match in amountRegex.allMatches(text)) {
      final amountStr = match.group(0)!.replaceAll(RegExp(r'[^\d.]'), '');
      final amount = double.tryParse(amountStr);
      if (amount == null) continue;

      final contextStart = (match.start - 15).clamp(0, text.length);
      final contextEnd = (match.end + 15).clamp(0, text.length);
      final context = text.substring(contextStart, contextEnd).toLowerCase();

      if (ignoreKeywords.any((kw) => context.contains(kw))) continue;

      suggestions.add(amount.toStringAsFixed(2));
    }

    return suggestions.toList()
      ..sort((a, b) => double.parse(b).compareTo(double.parse(a)));
  }

  String containsVAT(String text) {
    final vatRegex = RegExp(r'\bvat\b', caseSensitive: false);
    return vatRegex.hasMatch(text) ? 'Yes' : 'No';
  }
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});
}
