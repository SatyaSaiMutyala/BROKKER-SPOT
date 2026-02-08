import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/user/meeting/chat_view.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';
import 'package:flutter/material.dart';

class MeetingView extends StatefulWidget {
  const MeetingView({super.key});

  @override
  State<MeetingView> createState() => _MeetingViewState();
}

class _MeetingViewState extends State<MeetingView> {
  bool isBookingSelected = true;

  // Dummy data
  final List<Map<String, String>> bookingList = [
    {
      'name': 'Aman',
      'subtitle': 'SAFA/TWO\nFrom AED 99,000',
      'time': '2 min ago',
    }
  ];

  final List<Map<String, String>> announcementList = []; // empty for testing

  @override
  Widget build(BuildContext context) {
    final currentList = isBookingSelected ? bookingList : announcementList;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Meeting", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Tabs
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: CustomPrimaryButton(
                    title: 'Booking',
                    backgroundColor: isBookingSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    onPressed: () {
                      setState(() => isBookingSelected = true);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomPrimaryButton(
                    title: 'Announcement',
                    defaultColor:
                        !isBookingSelected ? AppColors.textWhite : Colors.black,
                    backgroundColor: !isBookingSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    onPressed: () {
                      setState(() => isBookingSelected = false);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: currentList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: currentList.length,
                    itemBuilder: (context, index) {
                      final item = currentList[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=100',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          item['name']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(item['subtitle']!),
                        trailing: Text(item['time']!),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ChatView()),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.info_outline, size: 48, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "No data found",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
