import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/services/user_service.dart';
import 'package:extendable_aiot/models/friend_model.dart';
import 'package:extendable_aiot/models/room_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final UserService _userService = UserService();
  String name = "";
  String email = "";
  Timestamp? createdAt;
  Timestamp? lastLogin;
  String userId = "";
  bool isLoading = true;

  // 添加好友相关状态
  List<FriendModel> _friends = [];
  bool _loadingFriends = true;
  List<RoomModel> _rooms = [];
  bool _loadingRooms = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFriends();
    _loadRooms();
  }

  void _loadUserData() {
    _userService.getUserData().listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          setState(() {
            name = data['name'] as String? ?? "未命名用户";
            email = data['email'] as String? ?? "";
            createdAt = data['createdAt'] as Timestamp?;
            lastLogin = data['lastLogin'] as Timestamp?;
            userId = snapshot.id;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      },
      onError: (error) {
        print("Error loading user data: $error");
        setState(() {
          isLoading = false;
        });
      },
    );
  }

  // 加载好友列表
  void _loadFriends() {
    _userService.getFriends().listen(
      (friendsList) {
        setState(() {
          _friends = friendsList;
          _loadingFriends = false;
        });
      },
      onError: (error) {
        print("Error loading friends: $error");
        setState(() {
          _loadingFriends = false;
        });
      },
    );
  }

  // 加载房间列表，用于授权好友访问
  void _loadRooms() {
    RoomModel.getAllRooms().listen(
      (roomsList) {
        setState(() {
          _rooms = roomsList;
          _loadingRooms = false;
        });
      },
      onError: (error) {
        print("Error loading rooms: $error");
        setState(() {
          _loadingRooms = false;
        });
      },
    );
  }

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
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(
                        'assets/avatar_placeholder.png',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),

                    _buildInfoCard(localizations),

                    const SizedBox(height: 20),
                    _buildFriendsCard(localizations),

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
              value: createdAt != null ? "${createdAt!.toDate()}" : "N/A",
            ),
            const Divider(),
            _InfoRow(title: localizations?.id ?? "ID", value: userId),
            const Divider(),
            _InfoRow(title: localizations?.email ?? "Email", value: email),
            const Divider(),
            _InfoRow(
              title: localizations?.lastLogin ?? "Last Login",
              value: lastLogin != null ? "${lastLogin!.toDate()}" : "N/A",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsCard(AppLocalizations? localizations) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations?.friendList ?? "好友列表",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => _showAddFriendDialog(localizations),
                  tooltip: localizations?.addFriend ?? '添加好友',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _loadingFriends
                ? const Center(child: CircularProgressIndicator())
                : _friends.isEmpty
                ? Center(child: Text(localizations?.noFriends ?? '还没有添加好友'))
                : Column(
                  children:
                      _friends.map((friend) {
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(friend.name),
                          subtitle: Text(friend.email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.home),
                                onPressed:
                                    () => _showAddToRoomDialog(
                                      friend,
                                      localizations,
                                    ),
                                tooltip: localizations?.addToRoom ?? '添加到房间',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () => _showDeleteFriendDialog(
                                      friend,
                                      localizations,
                                    ),
                                tooltip: localizations?.deleteFriend ?? '删除好友',
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  try {
                    // 更新到Firebase
                    await _userService.createOrUpdateUser(
                      name: newName,
                      email: email,
                    );

                    // 本地状态更新 (实际上会由监听器更新)
                    setState(() {
                      name = newName;
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(localizations?.nameUpdated ?? '名字已更新'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${localizations?.updateError ?? '更新失败'}: $e',
                          ),
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(localizations?.save ?? '儲存'),
            ),
          ],
        );
      },
    );
  }

  // 添加好友对话框
  void _showAddFriendDialog(AppLocalizations? localizations) {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations?.addFriend ?? '添加好友'),
            content: TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: localizations?.enterEmail ?? '请输入好友邮箱',
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations?.cancel ?? '取消'),
              ),
              TextButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isNotEmpty && email.contains('@')) {
                    Navigator.pop(context);

                    // 显示加载指示器
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) => AlertDialog(
                            content: Row(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(width: 20),
                                Text(
                                  localizations?.addingFriend ?? '正在添加好友...',
                                ),
                              ],
                            ),
                          ),
                    );

                    try {
                      final result = await _userService.addFriend(email);

                      if (mounted) {
                        Navigator.pop(context); // 关闭加载对话框

                        if (result) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations?.friendAdded ?? '好友添加成功',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations?.friendAddFailed ??
                                    '添加好友失败，该用户可能不存在或已是您的好友',
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context); // 关闭加载对话框
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${localizations?.error ?? '错误'}: $e',
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
                child: Text(localizations?.add ?? '添加'),
              ),
            ],
          ),
    );
  }

  // 显示将好友添加到房间的对话框
  void _showAddToRoomDialog(
    FriendModel friend,
    AppLocalizations? localizations,
  ) {
    if (_loadingRooms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.loadingRooms ?? '正在加载房间列表...')),
      );
      return;
    }

    if (_rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.noRooms ?? '您还没有创建任何房间')),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations?.selectRoom ?? '选择房间'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _rooms.length,
                itemBuilder: (context, index) {
                  final room = _rooms[index];
                  final isAuthorized = friend.sharedRooms.contains(room.id);

                  return ListTile(
                    title: Text(room.name),
                    trailing:
                        isAuthorized
                            ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
                            : const Icon(Icons.add_circle_outline),
                    onTap: () async {
                      if (isAuthorized) {
                        // 已经授权，询问是否要移除权限
                        final shouldRemove = await _showConfirmDialog(
                          context,
                          localizations?.removeAccess ?? '移除访问权限',
                          localizations?.confirmRemoveAccess ??
                              '确定要移除该好友对此房间的访问权限吗？',
                          localizations,
                        );

                        if (shouldRemove == true) {
                          await _userService.removeFriendFromRoom(
                            friend.id,
                            room.id,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  localizations?.accessRemoved ?? '访问权限已移除',
                                ),
                              ),
                            );
                          }
                        }
                      } else {
                        // 添加授权
                        await _userService.addFriendToRoom(friend.id, room.id);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations?.accessGranted ?? '访问权限已授予',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations?.close ?? '关闭'),
              ),
            ],
          ),
    );
  }

  // 确认删除好友对话框
  void _showDeleteFriendDialog(
    FriendModel friend,
    AppLocalizations? localizations,
  ) async {
    final shouldDelete = await _showConfirmDialog(
      context,
      localizations?.deleteFriend ?? '删除好友',
      localizations?.confirmDeleteFriend(friend.name) ??
          '确定要删除好友 ${friend.name} 吗？所有相关的房间访问权限也会被删除。',
      localizations,
    );

    if (shouldDelete == true) {
      try {
        final result = await _userService.removeFriend(friend.id);

        if (mounted && result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations?.friendRemoved ?? '好友已删除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${localizations?.error ?? '错误'}: $e')),
          );
        }
      }
    }
  }

  // 通用确认对话框
  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
    AppLocalizations? localizations,
  ) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(localizations?.cancel ?? '取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(localizations?.confirm ?? '确认'),
              ),
            ],
          ),
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
