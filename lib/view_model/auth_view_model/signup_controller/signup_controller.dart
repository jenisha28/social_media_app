import 'dart:async';

import 'package:email_otp/email_otp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:map_location_picker/map_location_picker.dart';
import 'package:social_media_app/data/app_preference/app_preference.dart';
import 'package:social_media_app/main.dart';
import 'package:social_media_app/res/components/network_checker/internet_checker.dart';
import 'package:social_media_app/res/routes/route_names.dart';
import 'package:social_media_app/services/analytics_service/analytics_service.dart';
import 'package:social_media_app/services/email_verification_service/email_verification_service.dart';
import 'package:social_media_app/services/encryption_service/encryption_service.dart';

enum Gender { male, female, other }

class SignupController extends GetxController {
  final _analyticsService = AnalyticsService();
  final internetChecker = Get.put(InternetChecker());

  late DateTime selectedDate = DateTime.now();
  final dateController = TextEditingController();
  final addressController = TextEditingController();
  final otpController = TextEditingController();
  RxString userid = ''.obs;
  RxString username = ''.obs;
  RxString email = ''.obs;
  RxString dob = ''.obs;
  RxString contact = ''.obs;
  RxString password = ''.obs;
  RxString cPassword = ''.obs;
  RxBool passwordVisible = false.obs;
  RxBool cPasswordVisible = false.obs;
  RxBool isAuthenticating = false.obs;

  RxString address = "".obs;
  RxString autocompletePlace = "".obs;

  Gender? selectedGender;

  RxString verificationEmail = ''.obs;
  bool isSelectedGender = true;

  RxString emailId = "".obs;
  RxString pwd = "".obs;
  RxString cPwd = "".obs;

  final formKey = GlobalKey<FormState>();

  Future resendOTP() async {
    try {
      if (internetChecker.isInternetConnected) {
        EmailOTP.config(
          appName: 'Social Media App',
          otpType: OTPType.numeric,
          expiry: 30000,
          emailTheme: EmailTheme.v6,
          appEmail: 'socialmediaapp@gmail.com',
          otpLength: 6,
        );
        EmailOTP.sendOTP(email: verificationEmail.value);
      } else {
        Get.snackbar("Internet Error", "Please Check Your Internet Connection");
      }
    } on FirebaseAuthException catch (error) {
      Get.snackbar(
          "Authentication Exception", error.message ?? 'auth_failed'.tr);
    }
  }

  Future verifyOtp(String otp) async {
    try {
      var result = EmailOTP.verifyOTP(otp: otp);

      if (result == true) {
        final userCredentials = await firebase.createUserWithEmailAndPassword(
            email: email.value, password: password.value);

        EncryptionService().init();
        String encryptedPassword =
            EncryptionService().encryptData(password.value);

        await databaseRef
            .child(userCredentials.user!.uid)
            .set(<String, dynamic>{
          'userid_key'.tr: userid.value,
          'username_key'.tr: username.value,
          'email_key'.tr: email.value,
          'dob_key'.tr: dob.value,
          'gender_key'.tr: selectedGender!.name,
          'contact_key'.tr: contact.value,
          'location_key'.tr: address.value,
          'password': encryptedPassword,
          'followers_key'.tr: 0,
          'followings_key'.tr: 0,
          'bio_key'.tr: '',
          'prof_img_key'.tr: '',
        });

        Get.offNamed(RouteNames.navMenu);
      } else {
        Get.snackbar("Invalid OTP", "Please re-enter your OTP");
      }
    } on Exception catch (error) {
      Get.snackbar("Authentication Exception", error.toString());
    }
  }

  Future<void> submit() async {
    try {
      isAuthenticating.value = true;
      if (internetChecker.isInternetConnected) {
        if (formKey.currentState!.validate()) {
          if (selectedGender != null) {
            isSelectedGender = true;
            formKey.currentState!.save();
            if (password == cPassword) {
              verificationEmail.value = email.value;
              await EmailVerificationService.sendOTP(verificationEmail.value);
              Get.toNamed(RouteNames.otpVerificationScreen);
              isAuthenticating.value = false;
            } else {
              isAuthenticating.value = false;
              Get.snackbar(
                  'Incorrect Password', 'Please Enter Correct Password');
            }
          } else {
            isSelectedGender = false;
          }
        } else {
          isAuthenticating.value = false;
        }
      } else {
        isAuthenticating.value = false;
        Get.snackbar("Internet Error", "Please Check Your Internet Connection");
      }
    } on FirebaseAuthException catch (error) {
      isAuthenticating.value = false;
      Get.snackbar(
          "Error in Authentication", error.message ?? 'auth_failed'.tr);
    }
  }

  Future<void> signupWithEmailPassword() async {
    try {
      if (internetChecker.isInternetConnected) {
        if (formKey.currentState!.validate()) {
          formKey.currentState!.save();
          if (pwd == cPwd) {
            verificationEmail.value = emailId.value;
            email.value = emailId.value;
            password.value = pwd.value;
            await EmailVerificationService.sendOTP(verificationEmail.value);
            Get.toNamed(RouteNames.emailVerificationScreen);
            isAuthenticating.value = false;
          } else {
            Get.snackbar('Incorrect Password', 'Please Enter Correct Password');
            isAuthenticating.value = false;
          }
        } else {
          isSelectedGender = false;
          isAuthenticating.value = false;
        }
      } else {
        isAuthenticating.value = false;
        Get.snackbar("Internet Error", "Please Check Your Internet Connection");
      }
    } on FirebaseAuthException catch (error) {
      isAuthenticating.value = false;
      Get.snackbar(
          "Error in Authentication", error.message ?? 'auth_failed'.tr);
    }
  }

  Future verifyEmailOtp(String otp) async {
    isAuthenticating.value = true;
    try {
      if (internetChecker.isInternetConnected) {
        var result = EmailOTP.verifyOTP(otp: otp);

        if (result == true) {
          AppPreference.setPreference('user_preference_key'.tr, true);
          final userCredentials = await firebase.createUserWithEmailAndPassword(
              email: emailId.value, password: pwd.value);
          _analyticsService.setUserId(userCredentials.user!.uid);
          _analyticsService.logSignUpWithEmailPassword(email: emailId.value);

          EncryptionService().init();
          String encryptedPassword = EncryptionService().encryptData(pwd.value);

          await databaseRef
              .child(userCredentials.user!.uid)
              .set(<String, dynamic>{
            'username_key'.tr: '',
            'email_key'.tr: userCredentials.user!.email,
            'dob_key'.tr: '',
            'gender_key'.tr: '',
            'contact_key'.tr: '',
            'location_key'.tr: '',
            'followers_key'.tr: 0,
            'followings_key'.tr: 0,
            'password': encryptedPassword,
            'bio_key'.tr: '',
            'prof_img_key'.tr: '',
          });

          /*  await FirebaseFirestore.instance
              .collection("Users")
              .doc(userCredentials.user!.uid)
              .set({
            'username_key'.tr: '',
            'email_key'.tr: userCredentials.user!.email,
            'dob_key'.tr: '',
            'gender_key'.tr: '',
            'contact_key'.tr: '',
            'location_key'.tr: '',
            'followers_key'.tr: 0,
            'followings_key'.tr: 0,
            'bio_key'.tr: '',
            'prof_img_key'.tr: '',
          }); */

          isAuthenticating.value = false;
          Get.offNamed(RouteNames.navMenu);
        } else {
          isAuthenticating.value = false;
          Get.snackbar("Invalid OTP", "Please re-enter your OTP");
        }
      } else {
        isAuthenticating.value = false;
        Get.snackbar("Internet Error", "Please Check Your Internet Connection");
      }
    } on Exception catch (error) {
      isAuthenticating.value = false;
      Get.snackbar("Authentication Exception", error.toString());
    }
  }

  void openMap() async {
    Get.to(
      MapLocationPicker(
        hideMapTypeButton: true,
        backButton: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Icons.arrow_back),
        ),
        apiKey: "MAP_API_KEY",
        popOnNextButtonTaped: true,
        currentLatLng: const LatLng(21.183509, 72.783102),
        debounceDuration: const Duration(milliseconds: 500),
        onNext: (GeocodingResult? result) {
          if (result != null) {
            addressController.text = result.formattedAddress ?? "";
          }
        },
        onSuggestionSelected: (PlacesDetailsResponse? result) {
          if (result != null) {
            autocompletePlace.value = result.result.formattedAddress ?? "";
          }
        },
      ),
    );
  }
}
