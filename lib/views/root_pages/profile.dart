import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String name = "yunitrish";

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations?.profile ?? 'Profile',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/avatar_placeholder.png'),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            _buildInfoCard(localizations),

            const SizedBox(height: 20),
            _buildFamilyList(localizations),

            const SizedBox(height: 20),
            _buildFunctionList(localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(AppLocalizations? localizations) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(
              title: localizations?.createdAt ?? "Created At",
              value: "2025年4月24日 凌晨4:22:06 [UTC+8]",
            ),
            const Divider(),
            _InfoRow(
              title: localizations?.id ?? "ID",
              value: "xxxxxxxxxxxxxxxxxxx",
            ),
            const Divider(),
            _InfoRow(
              title: localizations?.email ?? "Email",
              value: "yunitrish0419@gmail.com",
            ),
            const Divider(),
            _InfoRow(
              title: localizations?.lastLogin ?? "Last Login",
              value: "2025年4月24日 凌晨4:36:38 [UTC+8]",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyList(AppLocalizations? localizations) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.familyList ?? "家人列表",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('爸爸'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('媽媽'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('哥哥'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionList(AppLocalizations? localizations) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.functions ?? "功能",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(localizations?.changeName ?? '更改名字'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _changeNameDialog(localizations),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(localizations?.logout ?? '登出'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _changeNameDialog(AppLocalizations? localizations) {
    TextEditingController controller = TextEditingController(text: name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations?.changeName ?? '更改名字'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: localizations?.enterNewName ?? "輸入新的名字",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations?.cancel ?? '取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  name = controller.text;
                });
                Navigator.pop(context);
              },
              child: Text(localizations?.save ?? '儲存'),
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
