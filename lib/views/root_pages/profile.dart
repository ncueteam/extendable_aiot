import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/services/user_service.dart';
import 'package:extendable_aiot/models/friend_model.dart';
import 'package:extendable_aiot/models/room_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final UserService _userService = UserService();
  String name = "";
  String email = "";
  String? photoURL; // 添加頭像URL
  Timestamp? createdAt;
  Timestamp? lastLogin;
  String userId = "";
  bool isLoading = true;

  // 新增好友相關狀態
  List<FriendModel> _friends = [];
  bool _loadingFriends = true;
  List<RoomModel> _rooms = [];
  bool _loadingRooms = true;

  // 添加用於保存訂閱的變數
  StreamSubscription? _userDataSubscription;
  StreamSubscription? _friendsSubscription;
  StreamSubscription? _roomsSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFriends();
    _loadRooms();
  }

  @override
  void dispose() {
    // 取消所有訂閱以避免內存洩漏和錯誤
    _userDataSubscription?.cancel();
    _friendsSubscription?.cancel();
    _roomsSubscription?.cancel();
    super.dispose();
  }

  Widget getAvatar(String? url) {
    if (url == null) {
      return Icon(Icons.person, size: 50, color: Colors.grey);
    } else {
      return CircleAvatar(radius: 50, backgroundImage: NetworkImage(url));
    }
  }

  void _loadUserData() {
    _userDataSubscription = _userService.getUserData().listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          if (mounted) {
            // 添加判斷確保組件還在
            setState(() {
              name = data['name'] as String? ?? "未命名使用者";
              email = data['email'] as String? ?? "";
              photoURL = data['photoURL'] as String?; // 獲取頭像URL
              createdAt = data['createdAt'] as Timestamp?;
              lastLogin = data['lastLogin'] as Timestamp?;
              userId = snapshot.id;
              isLoading = false;
            });
          }
        } else {
          if (mounted) {
            // 添加判斷確保組件還在
            setState(() {
              isLoading = false;
            });
          }
        }
      },
      onError: (error) {
        print("載入使用者資料錯誤: $error");
        if (mounted) {
          // 添加判斷確保組件還在
          setState(() {
            isLoading = false;
          });
        }
      },
    );
  }

  // 載入好友列表
  void _loadFriends() {
    _friendsSubscription = _userService.getFriends().listen(
      (friendsList) {
        if (mounted) {
          // 添加判斷確保組件還在
          setState(() {
            _friends = friendsList;
            _loadingFriends = false;
          });
        }
      },
      onError: (error) {
        print("載入好友錯誤: $error");
        if (mounted) {
          // 添加判斷確保組件還在
          setState(() {
            _loadingFriends = false;
          });
        }
      },
    );
  }

  // 載入房間列表，用於授權好友訪問
  void _loadRooms() {
    _roomsSubscription = RoomModel.getAllRooms().listen(
      (roomsList) {
        if (mounted) {
          // 添加判斷確保組件還在
          setState(() {
            _rooms = roomsList;
            _loadingRooms = false;
          });
        }
      },
      onError: (error) {
        print("載入房間錯誤: $error");
        if (mounted) {
          // 添加判斷確保組件還在
          setState(() {
            _loadingRooms = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations?.profile ?? '個人資料',
          style: const TextStyle(color: Colors.black),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    getAvatar(photoURL),
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
              title: localizations?.createdAt ?? "建立時間",
              value: createdAt != null ? "${createdAt!.toDate()}" : "無資料",
            ),
            const Divider(),
            _InfoRow(title: localizations?.id ?? "ID", value: userId),
            const Divider(),
            _InfoRow(title: localizations?.email ?? "電子郵件", value: email),
            const Divider(),
            _InfoRow(
              title: localizations?.lastLogin ?? "上次登入",
              value: lastLogin != null ? "${lastLogin!.toDate()}" : "無資料",
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
                  tooltip: localizations?.addFriend ?? '新增好友',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _loadingFriends
                ? const Center(child: CircularProgressIndicator())
                : _friends.isEmpty
                ? Center(child: Text(localizations?.noFriends ?? '還沒有新增好友'))
                : Column(
                  children:
                      _friends.map((friend) {
                        return ListTile(
                          leading: getAvatar(friend.photoURL),
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
                                tooltip: localizations?.addToRoom ?? '新增至房間',
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
                                tooltip: localizations?.deleteFriend ?? '刪除好友',
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

                    // 本地狀態更新 (實際上會由監聽器更新)
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
                            '${localizations?.updateError ?? '更新失敗'}: $e',
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

  // 新增好友對話框
  void _showAddFriendDialog(AppLocalizations? localizations) {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations?.addFriend ?? '新增好友'),
            content: TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: localizations?.enterEmail ?? '請輸入好友電子郵件',
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

                    // 顯示載入指示器
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
                                  localizations?.addingFriend ?? '正在新增好友...',
                                ),
                              ],
                            ),
                          ),
                    );

                    try {
                      final result = await _userService.addFriend(email);

                      if (mounted) {
                        Navigator.pop(context); // 關閉載入對話框

                        if (result) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations?.friendAdded ?? '好友新增成功',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations?.friendAddFailed ??
                                    '新增好友失敗，該用戶可能不存在或已是您的好友',
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context); // 關閉載入對話框
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${localizations?.error ?? '錯誤'}: $e',
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
                child: Text(localizations?.add ?? '新增'),
              ),
            ],
          ),
    );
  }

  // 顯示將好友新增到房間的對話框
  void _showAddToRoomDialog(
    FriendModel friend,
    AppLocalizations? localizations,
  ) {
    if (_loadingRooms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.loadingRooms ?? '正在載入房間列表...')),
      );
      return;
    }

    if (_rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.noRooms ?? '您還沒有建立任何房間')),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations?.selectRoom ?? '選擇房間'),
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
                        // 已經授權，詢問是否要移除權限
                        final shouldRemove = await _showConfirmDialog(
                          context,
                          localizations?.removeAccess ?? '移除存取權限',
                          localizations?.confirmRemoveAccess ??
                              '確定要移除該好友對此房間的存取權限嗎？',
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
                                  localizations?.accessRemoved ?? '存取權限已移除',
                                ),
                              ),
                            );
                          }
                        }
                      } else {
                        // 新增授權
                        await _userService.addFriendToRoom(friend.id, room.id);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations?.accessGranted ?? '存取權限已授予',
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
                child: Text(localizations?.close ?? '關閉'),
              ),
            ],
          ),
    );
  }

  // 確認刪除好友對話框
  void _showDeleteFriendDialog(
    FriendModel friend,
    AppLocalizations? localizations,
  ) async {
    final shouldDelete = await _showConfirmDialog(
      context,
      localizations?.deleteFriend ?? '刪除好友',
      localizations?.confirmDeleteFriend(friend.name) ??
          '確定要刪除好友 ${friend.name} 嗎？所有相關的房間存取權限也會被刪除。',
      localizations,
    );

    if (shouldDelete == true) {
      try {
        final result = await _userService.removeFriend(friend.id);

        if (mounted && result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations?.friendRemoved ?? '好友已刪除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${localizations?.error ?? '錯誤'}: $e')),
          );
        }
      }
    }
  }

  // 通用確認對話框
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
                child: Text(localizations?.confirm ?? '確認'),
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
