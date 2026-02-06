import 'package:flutter/material.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using a Placeholder for the Illustration
            Container(
              height: 250,
              child: Center(
                child: Icon(Icons.hourglass_bottom_rounded,
                    size: 100, color: Colors.grey[400]),
                // In a real app, use: Image.asset('assets/verification_img.png')
              ),
            ),
            SizedBox(height: 40),
            Text(
              "Your Account Is In Under Verification Process, Please Wait We Will Activate Your Account Soon.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
