// Logging out has to take the account off the screen with it. Both of these
// controllers are permanent, so without an explicit reset a guest browsing
// right after a logout was greeted by the previous account's name and photo,
// and the login form came back prefilled with its credentials.
import 'package:brokkerspot/views/auth/controller/login_controller.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clearing the profile forgets the account', () {
    final c = ProfileController();
    c.applyProfileData({
      '_id': 'u1',
      'name': 'Satya',
      'email': 'satya@example.com',
      'mobileNumber': '9912821123',
      'userProfileImage': 'https://x/u.jpg',
      'brokerProfileImage': 'https://x/b.jpg',
      'role': 3,
      'currentRole': 2,
      'account_type': 1,
      'dealingCities': ['Dubai'],
      'verificationStatus': 'approved',
    });
    expect(c.hasBrokerRole, isTrue);

    c.clear();

    expect(c.userName.value, '');
    expect(c.userEmail.value, '');
    expect(c.profileImage.value, '');
    expect(c.brokerProfileImage.value, '');
    expect(c.role.value, 0);
    expect(c.currentRole.value, 0);
    expect(c.hasBrokerRole, isFalse);
    expect(c.profileData.value, isNull);
    expect(c.verificationStatus, isNull);
    expect(c.currentUserId, isNull);
    expect(c.dealingCities, isEmpty);
  });

  test('clearing the login form drops the typed credentials', () {
    final c = LoginController();
    c.emailController.text = 'satya@example.com';
    c.passwordController.text = 'secret';
    c.validateForm();
    expect(c.isFormValid.value, isTrue);

    c.clearForm();

    expect(c.emailController.text, '');
    expect(c.passwordController.text, '');
    expect(c.isFormValid.value, isFalse);
  });
}
