import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class BrokerProjectsView extends StatelessWidget {
  const BrokerProjectsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar('Projects'),
      body: Center(
        child: Text(
          'Broker Projects',
          style: GoogleFonts.inter(fontSize: 16.sp),
        ),
      ),
    );
  }

  AppBar _appBar(String title) {
    return AppBar(
      centerTitle: true,
      title: Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    );
  }
}
