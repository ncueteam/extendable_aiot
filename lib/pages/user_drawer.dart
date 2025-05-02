import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:extendable_aiot/services/user_service.dart';

class UserDrawer extends StatelessWidget {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: _userService.getUserData(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('載入失敗'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final user = _auth.currentUser;

          return Column(
            children: [
              UserAccountsDrawerHeader(
                currentAccountPicture: CircleAvatar(
                  child:
                      user!.photoURL!.isEmpty
                          ? const Icon(Icons.person, size: 40)
                          : ClipOval(
                            child: Image.network(
                              user.photoURL!,
                              fit: BoxFit.cover,
                              width: 70,
                              height: 70,
                            ),
                          ),
                ),
                accountName: Text(userData?['name'] ?? '未設定名稱'),
                accountEmail: Text(user.email ?? '未設定信箱'),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(localizations?.profile ?? '個人資料'),
                onTap: () {
                  // TODO: 導航到個人資料編輯頁面
                },
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('房間管理'),
                onTap: () {
                  // TODO: 導航到房間管理頁面
                },
              ),
              ListTile(
                leading: const Icon(Icons.device_hub),
                title: const Text('設備管理'),
                onTap: () {
                  // TODO: 導航到設備管理頁面
                },
              ),
              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(localizations?.settings ?? '設定'),
                onTap: () {
                  // TODO: 導航到設定頁面
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(localizations?.logout ?? '登出'),
                onTap: () async {
                  await _auth.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
