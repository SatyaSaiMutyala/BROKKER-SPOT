import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomPrimaryButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final double height;
  final double radius;
  final Color? backgroundColor;
  final bool isDisabled;
  final Color defaultColor;

  const CustomPrimaryButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.height = 50,
    this.radius = 8,
    this.backgroundColor,
    this.isDisabled = false,
    this.defaultColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? Colors.grey : backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          elevation: 0,
        ),
        child: Text(
          title,
          style: GoogleFonts.roboto(
            color: defaultColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
