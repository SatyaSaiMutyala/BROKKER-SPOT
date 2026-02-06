import 'package:brokkerspot/views/brokker/brokker_account/broker_account_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/instance_manager.dart';
import 'package:google_fonts/google_fonts.dart';

class BrokerProfileView extends StatelessWidget {
  const BrokerProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:
            Text('My Account', style: GoogleFonts.roboto(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.settings_outlined, color: Colors.orangeAccent),
            onPressed: () {
              Get.to(() => AccountMenuView());
            },
          ),
          SizedBox(
            width: 16,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildInfoSection("Areas", "Downtown, Business Bay, Merina"),
            _buildInfoSection("Language", "English, French, Hindi, Urdu"),
            _buildAboutSection(),
            const SizedBox(height: 20),
            _buildBoostBanner(),
            const SizedBox(height: 24),
            _buildTimelineHeader(),
            const SizedBox(height: 12),
            _buildHorizontalTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundImage: NetworkImage(
              'https://via.placeholder.com/150'), // Replace with actual image
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Experience: 5 Year",
                  style: GoogleFonts.roboto(color: Colors.grey)),
              Text("Following: 20",
                  style: GoogleFonts.roboto(color: Colors.grey)),
              const SizedBox(height: 8),
              Text("License",
                  style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
              Text("BRN: 18566   ORN: 21556",
                  style: GoogleFonts.roboto(fontSize: 12)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          Text(content, style: GoogleFonts.roboto(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBoostBanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Boost Your Profile For 7 days",
            style: GoogleFonts.roboto(
                color: Colors.orangeAccent, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text("AED 20",
              style: GoogleFonts.roboto(
                  color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildHorizontalTimeline() {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => Container(
          width: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: const DecorationImage(
              image: NetworkImage('https://via.placeholder.com/150'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  // Custom helper for brevity
  Widget _buildAboutSection() => Text(
      "About me\nIpsum is simply dummy text of the printing and typesetting industry...",
      style: GoogleFonts.roboto(color: Colors.grey));

  Widget _buildTimelineHeader() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("All Announcement Timeline",
              style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
          Text("More", style: GoogleFonts.roboto(color: Colors.orangeAccent)),
        ],
      );
}
