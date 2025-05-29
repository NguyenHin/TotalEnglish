import 'package:flutter/material.dart';

class AppLocalizations {
  static const List<String> languages = ['Tiếng Việt', 'English'];

  static String getTitle(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'vi'
        ? 'Tài khoản'
        : 'Account';
  }

  static String getPersonalInfo(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'vi'
        ? 'Thông tin cá nhân'
        : 'Personal Information';
  }

  static String getLogout(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'vi'
        ? 'Đăng xuất'
        : 'Logout';
  }

// Thêm các chuỗi khác tương tự
}