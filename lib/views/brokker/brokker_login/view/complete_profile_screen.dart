import 'dart:io';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/brokker/brokker_login/controller/complete_profile_controller.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/rules_screen.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final controller = Get.put(CompleteProfileController());

  final TextEditingController emailController = TextEditingController();
  final TextEditingController bnrValueController = TextEditingController();

  bool isAgent = true;
  bool isShowBNR = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Profile",
            style: TextStyle(color: Colors.black, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileImage(),
              const SizedBox(height: 20),
              _label("Upload your Passport *"),
              _uploadBox(
                height: 120,
                label: "Passport Photo",
                image: controller.passportImage,
              ),
              const SizedBox(height: 20),
              _label("Upload your Local ID *"),
              Row(
                children: [
                  Expanded(
                    child: _uploadBox(
                      height: 100,
                      label: "Front Side",
                      image: controller.idFrontImage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _uploadBox(
                      height: 100,
                      label: "Back Side",
                      image: controller.idBackImage,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _dropdown(
                "Country",
                ["India", "UAE", "USA"],
                controller.selectedCountry,
              ),
              _dropdown(
                "City",
                ["Hyderabad", "Dubai", "New York"],
                controller.selectedCity,
              ),
              _dropdown(
                "Experience",
                ["0-1 Years", "1-3 Years", "3+ Years"],
                controller.selectedExperience,
              ),
              _languageMultiSelect(),
              _label("Professional Email (Optional)"),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              _agentBrokerToggle(),
              const SizedBox(height: 20),
              if (isShowBNR) _label("BNR"),
              if (isShowBNR)
                TextFormField(
                  controller: bnrValueController,
                  decoration: const InputDecoration(
                    hintText: "BNR",
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 20),
              CustomPrimaryButton(
                title: 'Next',
                backgroundColor: AppColors.primary,
                onPressed: () {
                  if (isShowBNR == false) {
                    setState(() {
                      isShowBNR = true;
                    });
                  } else {
                    Get.to(() => const RulesScreen());
                    // if (_formKey.currentState!.validate()) {
                    //   _submitForm();
                    // }
                  }
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "GDPR: Your data will be deleted 72h after verification.",
                style: TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- UI Widgets ----------------

  Widget _profileImage() {
    return Center(
      child: GestureDetector(
        onTap: () => controller.pickImage(controller.profileImage),
        child: Stack(
          children: [
            Obx(() {
              return CircleAvatar(
                radius: 50,
                backgroundImage: controller.profileImage.value != null
                    ? FileImage(controller.profileImage.value!)
                    : null,
                backgroundColor: Colors.grey[200],
                child: controller.profileImage.value == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              );
            }),
            const Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Colors.orange,
                child: Icon(Icons.edit, size: 15, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadBox({
    required double height,
    required String label,
    required Rx<File?> image,
  }) {
    return GestureDetector(
      onTap: () => controller.pickImage(image),
      child: Obx(() {
        return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: image.value != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    image.value!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined, color: Colors.orange),
                    const SizedBox(height: 5),
                    Text(label,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
        );
      }),
    );
  }

  Widget _dropdown(String label, List<String> items, RxString value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Obx(() {
          return DropdownButtonFormField<String>(
            value: value.value.isEmpty ? null : value.value,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => value.value = val ?? '',
            decoration: const InputDecoration(border: OutlineInputBorder()),
          );
        }),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _languageMultiSelect() {
    final languages = ["English", "Hindi", "Telugu", "Tamil", "Arabic"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Languages you know"),
        MultiSelectDialogField(
          items: languages.map((e) => MultiSelectItem(e, e)).toList(),
          listType: MultiSelectListType.CHIP,
          onConfirm: (values) {
            controller.selectedLanguages.value = values.cast<String>();
          },
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _agentBrokerToggle() {
    return Row(
      children: [
        Expanded(
            child: CustomPrimaryButton(
          title: 'Agent',
          backgroundColor: isAgent ? AppColors.primary : Colors.grey[300],
          onPressed: () => setState(() => isAgent = true),
        )),
        const SizedBox(width: 10),
        Expanded(
            child: CustomPrimaryButton(
          title: 'Broker',
          backgroundColor: !isAgent ? AppColors.primary : Colors.grey[300],
          onPressed: () => setState(() => isAgent = false),
        )),
      ],
    );
  }

  // ---------------- Helpers ----------------

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  void _submitForm() {
    debugPrint("Email: ${emailController.text}");
    debugPrint("Country: ${controller.selectedCountry.value}");
    debugPrint("Languages: ${controller.selectedLanguages}");
  }
}
