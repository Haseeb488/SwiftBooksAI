import 'dart:convert';
import 'dart:io';
import 'package:edge_alerts/edge_alerts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Global.dart';
import 'MyProfileScreen.dart';
import 'MyReceiptsScreen.dart';
import 'login_page.dart';
import 'MyAccountantScreen.dart';
import 'ReceiptScannerPage.dart';
import 'main.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  final List<String> images = [
    'assets/grid/a.png',
    'assets/grid/b.png',
    'assets/grid/bill.png',
    'assets/grid/c.png',
  ];

  final List<String> titles = ['Camera', 'Gallery', 'My Receipts', 'Exit'];

  List<File> _allImageFiles = []; // Track all cropped files
  List<String> _allImageNames = [];
  File? _imageFile; // Keeps track of the current active image file

  final ImagePicker _picker = ImagePicker();
  String themePrefKey = 'theme_mode';

  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No image selected')));
        return;
      }

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Receipt',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Receipt', aspectRatioLockEnabled: false),
        ],
      );

      if (croppedFile != null) {
        final file = File(croppedFile.path);

        // Explicitly generate the filename right here
        final String generatedName =
            '${DateTime.now().millisecondsSinceEpoch}.jpg';

        setState(() {
          _imageFile = file;
          _allImageFiles.add(file); // Explicitly add the file to your list
          _allImageNames.add(
            generatedName,
          ); // Explicitly add the name to your list here!
        });

        bool isFirst = _allImageFiles.length == 1;

        // Pass both the file and its designated name to the upload function
        await _uploadReceiptImage(
          _imageFile!,
          imageName: generatedName,
          isFirstPage: isFirst,
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cropping cancelled')));
      }
    } catch (e) {
      print("Image picking/cropping error: $e");
    }
  }

  Future<void> _uploadReceiptImage(
    File file, {
    required String imageName,
    bool isFirstPage = true,
  }) async {
    try {
      showCircularProgress(context);
      const apiUrl =
          'https://securenet.justyes.co.uk/Prod/SwiftBooksApis/uploadImage.php';

      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      final encodedImage = base64Encode(await file.readAsBytes());

      request.fields['clientID'] = clientID;
      request.fields['encoded_string'] = encodedImage;
      request.fields['image_name'] = imageName; // Sets the correct name we just added to our list
      request.fields['isFirstPage'] = isFirstPage.toString();

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final responseJson = json.decode(responseData);

      Navigator.pop(context); // close loader

      print("response: " + responseJson.toString());

      if (response.statusCode == 200 && responseJson['success'] == true) {
        _askForMorePages(context);
      } else {
        // Safety Clean-up: If the API says it failed, remove them so the indices stay accurate
        setState(() {
          _allImageFiles.remove(file);
          _allImageNames.remove(imageName);
        });

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

      // Safety Clean-up on network exception
      setState(() {
        _allImageFiles.remove(file);
        _allImageNames.remove(imageName);
      });

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

  void _askForMorePages(BuildContext context) {
    bool isDarkMode = themeNotifier.value == ThemeMode.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    Text(
                      'Same invoice, next page?',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'To upload a different receipt, finish this one first. Multiple pages for same invoice only',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () {
                        if (!mounted) return;
                        Navigator.pop(context);
                        _pickNextPage();
                      },
                      child: const Text(
                        'Scan Next Page',
                        style: TextStyle(color: Colors.green, fontSize: 16),
                      ),
                    ),
                    Divider(
                      color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog

                        List<File> imagesToScan = [];

                        // 1. Get ONLY the first and last physical image files
                        if (_allImageFiles.isNotEmpty) {
                          imagesToScan.add(_allImageFiles.first);

                          if (_allImageFiles.length > 1) {
                            imagesToScan.add(_allImageFiles.last);
                          }
                        }

                        // 2. Safely grab ALL names collected in your array and join them by commas
                        String commaSeparatedNames = _allImageNames.join(',');

                        // 3. Complete navigation payload transfer
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReceiptScannerPage(
                              imageFile: imagesToScan,
                              imageNames: commaSeparatedNames,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'All Done,Thanks',
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

  Future<void> _pickNextPage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.blue,

      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take Photo"),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ImagePicker picker = ImagePicker();
                  final XFile? xfile = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (xfile != null) {
                    // 1. Run through ImageCropper for consistent formatting
                    final croppedFile = await ImageCropper().cropImage(
                      sourcePath: xfile.path,
                      uiSettings: [
                        AndroidUiSettings(
                          toolbarTitle: 'Crop Receipt',
                          toolbarColor: Theme.of(context).primaryColor,
                          toolbarWidgetColor: Colors.white,
                          initAspectRatio: CropAspectRatioPreset.original,
                          lockAspectRatio: false,
                        ),
                        IOSUiSettings(
                          title: 'Crop Receipt',
                          aspectRatioLockEnabled: false,
                        ),
                      ],
                    );

                    if (croppedFile != null) {
                      final File nextFile = File(croppedFile.path);

                      // 2. Explicitly generate the timestamp file name
                      final String generatedName =
                          '${DateTime.now().millisecondsSinceEpoch}.jpg';

                      // 3. Track both variables in our lists
                      setState(() {
                        _imageFile = nextFile;
                        _allImageFiles.add(nextFile);
                        _allImageNames.add(generatedName);
                      });

                      // 4. Pass the required dynamic arguments to the uploader
                      await _uploadReceiptImage(
                        nextFile,
                        imageName: generatedName,
                        isFirstPage: false,
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose from Gallery"),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ImagePicker picker = ImagePicker();
                  final XFile? xfile = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (xfile != null) {
                    // 1. Run through ImageCropper for consistent formatting
                    final croppedFile = await ImageCropper().cropImage(
                      sourcePath: xfile.path,
                      uiSettings: [
                        AndroidUiSettings(
                          toolbarTitle: 'Crop Receipt',
                          toolbarColor: Theme.of(context).primaryColor,
                          toolbarWidgetColor: Colors.white,
                          initAspectRatio: CropAspectRatioPreset.original,
                          lockAspectRatio: false,
                        ),
                        IOSUiSettings(
                          title: 'Crop Receipt',
                          aspectRatioLockEnabled: false,
                        ),
                      ],
                    );

                    if (croppedFile != null) {
                      final File nextFile = File(croppedFile.path);

                      // 2. Explicitly generate the timestamp file name
                      final String generatedName =
                          '${DateTime.now().millisecondsSinceEpoch}.jpg';

                      // 3. Track both variables in our lists
                      setState(() {
                        _imageFile = nextFile;
                        _allImageFiles.add(nextFile);
                        _allImageNames.add(generatedName);
                      });

                      // 4. Pass the required dynamic arguments to the uploader
                      await _uploadReceiptImage(
                        nextFile,
                        imageName: generatedName,
                        isFirstPage: false,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showExitDialog(BuildContext context) {
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
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.red : Colors.blue,
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
                      'Exit',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Do you want to exit the SwiftBookAI App',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () {
                        if (Platform.isAndroid) {
                          SystemNavigator.pop();
                        } else if (Platform.isIOS) {
                          exit(0);
                        }
                      },
                      child: const Text(
                        'Yes, Exit Swift Books AI',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                    Divider(
                      color: isDarkMode ? Colors.white12 : Colors.grey,
                      thickness: 1,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.green, fontSize: 16),
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

  Future<void> saveThemeToPrefs(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themePrefKey, mode.name);
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = themeNotifier.value == ThemeMode.dark;

    return PopScope(
      canPop: false, // Prevents default back navigation
      onPopInvoked: (didPop) {
        if (!didPop) {
          showExitDialog(context); // Your custom exit dialog
        }
      },

      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(
            color: isDarkMode ? Colors.white : Colors.blue,
          ),
          title: Text(
            '',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        drawer: Drawer(
          backgroundColor: isDarkMode ? Colors.black : Colors.grey[100],
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey.shade900
                      : Colors.blue.shade400,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.6),
                            blurRadius: 12,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Center(
                        child: const CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage(
                            'assets/images/profile.png',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        lastName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        clientEmail,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              ListTile(
                leading: Image.asset(
                  'assets/icons/profile.png', // replace with your asset path
                  width: 24,
                  height: 24,
                  //  color: isDarkMode ? Colors.white : Colors.black, // optional tint
                ),

                title: Text(
                  'My Profile',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyProfileScreen()),
                  );
                },
              ),
              Divider(
                color: isDarkMode ? Colors.white : Colors.black,
                thickness: 0.1,
                indent: 15,
                endIndent: 15,
              ),

              ListTile(
                leading: Image.asset(
                  'assets/icons/accountant.png', // replace with your asset path
                  width: 24,
                  height: 24,
                ),

                title: Text(
                  'Accountant',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyAccountantScreen(),
                    ),
                  );
                },
              ),

              Divider(
                color: isDarkMode ? Colors.white : Colors.black,
                thickness: 0.1,
                indent: 15,
                endIndent: 15,
              ),

              SwitchListTile(
                activeColor: Colors.blueAccent,
                inactiveThumbColor: Colors.grey,
                title: Text(
                  'Light Mode',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                secondary: Icon(
                  Icons.light_mode,
                  color: isDarkMode ? Colors.yellow : Colors.black,
                ),
                value: !isDarkMode,
                onChanged: (bool value) {
                  setState(() {
                    themeNotifier.value = value
                        ? ThemeMode.light
                        : ThemeMode.dark;
                    saveThemeToPrefs(themeNotifier.value);
                  });
                },
              ),
              Divider(
                color: isDarkMode ? Colors.white : Colors.black,
                thickness: 0.1,
                indent: 15,
                endIndent: 15,
              ),

              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: isDarkMode ? Colors.blue : Colors.black,
                ),
                title: Text(
                  'Sign Out',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const LoginPage(),
                      transitionsBuilder: (_, animation, __, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                      transitionDuration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 73, 111, 235),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(22),
                    top: Radius.circular(22),
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 32, 0, 0),
                      child: Column(
                        children: [
                          Text(
                            "Welcome",
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            lastName.length > 8
                                ? '${lastName.substring(0, 8)}...'
                                : lastName,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Image.asset('assets/images/cont1.png'),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Image.asset('assets/images/cont2.png'),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Image.asset('assets/images/cont3.png'),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(22),
                        ),
                        child: Image.asset(
                          'assets/images/home_3d.png',
                          scale: 1.3,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 1,
                      right: 293,
                      child: Image.asset('assets/images/block.png'),
                    ),
                    Positioned(
                      bottom: 1,
                      left: 330,
                      child: Image.asset('assets/images/box1.png'),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                itemCount: images.length,
                padding: const EdgeInsets.only(top: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 3.8,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      if (titles[index] == "Camera") {
                        if(accountantID == "")
                        {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyAccountantScreen(),
                            ),
                          );
                          return;
                        }
                        _getImage(ImageSource.camera);
                        return;
                      }
                      if (titles[index] == "Gallery") {

                        print("accountant id: "+accountantID);
                         if(accountantID == "")
                          {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyAccountantScreen(),
                              ),
                            );
                            return;
                          }

                        _getImage(ImageSource.gallery);
                        return;
                      }
                      if (titles[index] == "My Receipts") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyReceiptsScreen(),
                          ),
                        );
                        return;
                      }

                      if (titles[index] == "Exit") {
                        showExitDialog(context);
                        return;
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                      child: Container(
                        alignment: Alignment.center,
                        height: 60,
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color.fromARGB(40, 158, 158, 158),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(images[index], scale: 0.7),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 8,
                              ),
                              child: Text(
                                titles[index],
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
