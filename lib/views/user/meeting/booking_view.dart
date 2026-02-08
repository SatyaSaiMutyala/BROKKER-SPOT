import 'dart:io';
import 'package:brokkerspot/views/user/meeting/verification_wait_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'booking_controller.dart';

class BookingView extends StatelessWidget {
  BookingView({super.key});

  final BookingController c = Get.put(BookingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Color(0xFFE5E5E5)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios,
                  size: 14,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        title: const Text("Booking", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Obx(() => _stepper()),
          Expanded(
            child: PageView(
              controller: c.pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _infoStep(),
                _uploadStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= STEPPER =================

  Widget _stepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _step(
            number: "1",
            label: "INFORMATION",
            status: StepStatus.completed,
          ),
          _dottedLine(),
          _step(
            number: "2",
            label: "UPLOAD DOCUMENTS",
            status: c.currentStep.value == 1
                ? StepStatus.active
                : StepStatus.inactive,
          ),
        ],
      ),
    );
  }

  Widget _step({
    required String number,
    required String label,
    required StepStatus status,
  }) {
    Color borderColor;
    Widget inner;

    if (status == StepStatus.completed) {
      borderColor = Colors.green;
      inner = Text(number,
          style: const TextStyle(
              color: Colors.green, fontWeight: FontWeight.bold));
    } else if (status == StepStatus.active) {
      borderColor = const Color(0xFFFFA000);
      inner = Text(number,
          style: const TextStyle(
              color: Color(0xFFFFA000), fontWeight: FontWeight.bold));
    } else {
      borderColor = Colors.grey.shade400;
      inner = Text(number, style: TextStyle(color: Colors.grey.shade400));
    }

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: inner,
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _dottedLine() {
    return SizedBox(
      width: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          8,
          (_) => Container(width: 6, height: 1, color: Colors.grey.shade400),
        ),
      ),
    );
  }

  // ================= STEP 1 =================

  Widget _infoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _textField(c.nameCtrl, "Name"),
          _textField(c.emailCtrl, "Email"),
          _textField(c.phoneCtrl, "Phone", prefix: "+91"),
          Row(
            children: [
              Expanded(child: _dropdown(c.country, ["UAE", "INDIA"])),
              const SizedBox(width: 10),
              Expanded(child: _dropdown(c.city, ["DUBAI", "ABU DHABI"])),
            ],
          ),
          _dropdown(c.area, ["DOWNTOWN", "MARINA"]),
          _textField(c.pincodeCtrl, "Pincode"),
          _textField(c.addressCtrl, "Address", maxLines: 3),
          _textField(c.refCtrl, "Reference No"),
          const SizedBox(height: 20),
          _submitButton("SUBMIT", c.nextStep),
          Center(
            child: Text(
                "GDPR: Your data will be deleted 72h after verification of your identity",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // ================= STEP 2 =================

  Widget _uploadStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Upload Passport *"),
          Obx(() => _uploadBox(
                file: c.passportImage.value,
                onTap: () => c.pickImage(c.passportImage),
                height: 150,
              )),
          const SizedBox(height: 12),
          const Text("Upload Local ID *"),
          Row(
            children: [
              Expanded(
                child: Obx(() => _uploadBox(
                      file: c.idFrontImage.value,
                      label: "Front",
                      onTap: () => c.pickImage(c.idFrontImage),
                    )),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(() => _uploadBox(
                      file: c.idBackImage.value,
                      label: "Back",
                      onTap: () => c.pickImage(c.idBackImage),
                    )),
              ),
            ],
          ),
          const Spacer(),
          _submitButton("SUBMIT", () {
            Get.to(() => VerificationWaitView());
          }),
          Center(
            child: Text(
                "GDPR: Your data will be deleted 72h after verification of your identity",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // ================= COMMON =================

  Widget _textField(TextEditingController ctrl, String hint,
      {String? prefix, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefix,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _dropdown(RxString value, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Obx(
        () => DropdownButtonFormField<String>(
          value: value.value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => value.value = v!,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ),
    );
  }

  Widget _uploadBox({
    required VoidCallback onTap,
    File? file,
    double height = 120,
    String label = "",
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: file == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo, color: Color(0xFFD4AF37)),
                  if (label.isNotEmpty) Text(label),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    Image.file(file, fit: BoxFit.cover, width: double.infinity),
              ),
      ),
    );
  }

  Widget _submitButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF37),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

enum StepStatus { completed, active, inactive }
