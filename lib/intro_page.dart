import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swiftbook_ai/login_page.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        decoration: const BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage('assets/images/intro_img1.png'),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20.0), // prevent bottom overflow
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 300, 0, 0),
                  child: Text(
                    "Swift Scans\nfor Smart Accounting",
                    style: GoogleFonts.inter(
                      fontSize: 54,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "AI-Driven Receipt Scanner\nfor Accounting & Tax\nManagement.",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 110,
                ),
          
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: Container(
                    height: 60,
                    width: double.maxFinite,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/icons/ic_button.png"),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Get Started -> ",
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Image.asset("assets/icons/ic_intro_hand.png"),
                      ],
                    ),
                  ),
                )
          
            //****** This is the old way of mine to make the UI but the issue with this is if i try with different device then i have alignment issues ******//
                //     //button
                //     Positioned(
                //       bottom: MediaQuery.of(context).size.height * 0.05,
                //       left: MediaQuery.of(context).size.width * 0.1,
                //       right: MediaQuery.of(context).size.width * 0.1,
                //       child: GestureDetector(
                //         onTap: () {
                //           Navigator.push(
                //             context,
                //             MaterialPageRoute(
                //               builder: (context) => AuthCheckMain(),
                //             ),
                //           );
                //         },
                //         child: Image.asset("assets/icons/ic_button.png"),
                //       ),
                //     ),
                //     Positioned(
                //       bottom: MediaQuery.of(context).size.height * 0.065,
                //       left: 120,
                //       child: GestureDetector(
                //         onTap: () {
                //           Navigator.push(
                //             context,
                //             MaterialPageRoute(
                //               builder: (context) => AuthCheckMain(),
                //             ),
                //           );
                //         },
                //         child: Text(
                //           "Get Started ->",
                //           style: GoogleFonts.inter(
                //             fontSize: 22,
                //             fontWeight: FontWeight.w500,
                //           ),
                //         ),
                //       ),
                //     ),
                //     Positioned(
                //       bottom: MediaQuery.of(context).size.height * 0.060,
                //       right: 90,
                //       child: GestureDetector(
                //         onTap: () {
                //           Navigator.push(
                //             context,
                //             MaterialPageRoute(
                //               builder: (context) => AuthCheckMain(),
                //             ),
                //           );
                //         },
                //         child: Image.asset("assets/icons/ic_intro_hand.png"),
                //       ),
                //     ),
                //   ],
                // )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
