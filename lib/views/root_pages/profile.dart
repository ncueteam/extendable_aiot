import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/models/user_model.dart';
import 'package:extendable_aiot/models/abstract/room_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:app_chiseletor/widgets/user_avatar.dart'; // 導入 UserAvatar 元件
import 'dart:async';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  UserModel? _userModel;
  String name = "";
  String email = "";
  String? photoURL; // 添加頭像URL
  Timestamp? createdAt;
  Timestamp? lastLogin;
  String userId = "";
  bool isLoading = true;

  // 好友相關狀態
  List<UserModel> _friends = [];
  bool _loadingFriends = true;

  // 房間相關狀態
  List<RoomModel> _rooms = [];
  bool _loadingRooms = true;

  // 房間授權狀態 - 儲存每個房間授權的使用者ID
  Map<String, List<String>> _roomAuthorizations = {};

  // 保存訂閱
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

  void _loadUserData() {
    _userDataSubscription = UserModel.getCurrentUser().listen(
      (userModel) {
        if (userModel != null) {
          if (mounted) {
            // 添加判斷確保組件還在
            setState(() {
              _userModel = userModel;
              name = userModel.name;
              email = userModel.email;
              photoURL = userModel.photoURL;
              createdAt = userModel.createdAt;
              lastLogin = userModel.lastLogin;
              userId = userModel.id;
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
    if (UserModel.currentUserId == null) {
      setState(() {
        _loadingFriends = false;
      });
      return;
    }

    _friendsSubscription = UserModel(
      id: UserModel.currentUserId!,
      name: '',
      email: '',
    ).getFriendsStream().listen(
      (friendModels) {
        if (mounted) {
          // 添加判斷確保組件還在
          setState(() {
            _friends = friendModels;
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

  // 載入房間列表並獲取每個房間的授權用戶
  void _loadRooms() {
    _roomsSubscription = RoomModel.getAllRooms().listen(
      (roomsList) async {
        Map<String, List<String>> authorizations = {};

        // 獲取每個房間的授權用戶
        for (var room in roomsList) {
          // 每次迴圈開始前檢查 mounted 狀態
          if (!mounted) return;

          try {
            DocumentSnapshot roomDoc =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(UserModel.currentUserId)
                    .collection('rooms')
                    .doc(room.id)
                    .get();

            // 再次檢查 mounted 狀態
            if (!mounted) return;

            if (roomDoc.exists) {
              Map<String, dynamic> data =
                  roomDoc.data() as Map<String, dynamic>;
              authorizations[room.id] = List<String>.from(
                data['authorizedUsers'] ?? [],
              );
            } else {
              authorizations[room.id] = [];
            }
          } catch (error) {
            print("獲取房間授權用戶錯誤: $error");
            // 出錯也檢查 mounted 狀態
            if (!mounted) return;
          }
        }

        if (mounted) {
          setState(() {
            _rooms = roomsList;
            _roomAuthorizations = authorizations;
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
                    UserAvatar(imageUrl: photoURL),
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
                          leading: UserAvatar(imageUrl: friend.photoURL),
                          title: Text(friend.name),
                          subtitle: Text(friend.email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.home),
                                onPressed:
                                    () => _showAddToRoomDialog(
                                      friend.id,
                                      friend.name,
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
                                      friend.id,
                                      friend.name,
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
    // 與原來相同
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
    // 與原來相同
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
                if (newName.isNotEmpty && _userModel != null) {
                  try {
                    _userModel!.name = newName;
                    await _userModel!.createOrUpdate();

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
    bool isProcessing = false; // 添加處理狀態標誌

    showDialog(
      context: context,
      barrierDismissible: false, // 防止用戶點擊對話框外關閉
      builder: (dialogContext) {
        return StatefulBuilder(
          // 使用StatefulBuilder來更新對話框UI狀態
          builder: (context, setState) {
            return AlertDialog(
              title: Text(localizations?.addFriend ?? '新增好友'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: localizations?.enterEmail ?? '請輸入好友電子郵件',
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isProcessing, // 處理中禁用輸入
                  ),
                  if (isProcessing) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(width: 20),
                        Text(localizations?.addingFriend ?? '正在新增好友...'),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(context),
                  child: Text(localizations?.cancel ?? '取消'),
                ),
                TextButton(
                  onPressed:
                      isProcessing
                          ? null
                          : () async {
                            final email = emailController.text.trim();
                            if (email.isNotEmpty &&
                                email.contains('@') &&
                                _userModel != null) {
                              // 更新處理狀態
                              setState(() {
                                isProcessing = true;
                              });

                              try {
                                final result = await _userModel!.addFriend(
                                  email,
                                );

                                if (mounted) {
                                  Navigator.pop(context); // 操作完成後關閉對話框

                                  if (result) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          localizations?.friendAdded ??
                                              '好友新增成功',
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
                                  // 發生錯誤時，重設處理狀態，允許用戶重試
                                  setState(() {
                                    isProcessing = false;
                                  });

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
            );
          },
        );
      },
    );
  }

  // 顯示將好友新增到房間的對話框
  void _showAddToRoomDialog(
    String friendId,
    String friendName,
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
                  final isAuthorized =
                      _roomAuthorizations.containsKey(room.id) &&
                      _roomAuthorizations[room.id]!.contains(friendId);

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
                        // 已授權，詢問是否移除權限
                        final shouldRemove = await _showConfirmDialog(
                          context,
                          localizations?.removeAccess ?? '移除存取權限',
                          localizations?.confirmRemoveAccess ??
                              '確定要移除該好友對此房間的存取權限嗎？',
                          localizations,
                        );

                        // 檢查是否還掛載
                        if (!mounted) return;

                        if (shouldRemove == true) {
                          try {
                            await RoomModel.removeAuthorizedUser(
                              room.id,
                              friendId,
                            );

                            // 再次檢查是否還掛載
                            if (!mounted) return;

                            Navigator.pop(context);
                            // 刷新房間授權數據
                            _loadRooms();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  localizations?.accessRemoved ?? '存取權限已移除',
                                ),
                              ),
                            );
                          } catch (e) {
                            print("移除用戶授權錯誤: $e");
                            if (mounted) {
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
                      } else {
                        // 新增授權
                        try {
                          await RoomModel.addAuthorizedUser(room.id, friendId);

                          // 檢查是否還掛載
                          if (!mounted) return;

                          Navigator.pop(context);
                          // 刷新房間授權數據
                          _loadRooms();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations?.accessGranted ?? '存取權限已授予',
                              ),
                            ),
                          );
                        } catch (e) {
                          print("授予用戶權限錯誤: $e");
                          if (mounted) {
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
    String friendId,
    String friendName,
    AppLocalizations? localizations,
  ) async {
    final shouldDelete = await _showConfirmDialog(
      context,
      localizations?.deleteFriend ?? '刪除好友',
      localizations?.confirmDeleteFriend(friendName) ??
          '確定要刪除好友 $friendName 嗎？',
      localizations,
    );

    if (shouldDelete == true && _userModel != null) {
      try {
        final result = await _userModel!.removeFriend(friendId);

        if (!mounted) return; // 檢查組件是否仍然掛載

        if (result) {
          // 從所有房間移除授權
          for (var room in _rooms) {
            // 在每次迴圈中檢查組件是否仍然掛載
            if (!mounted) return;

            try {
              await RoomModel.removeAuthorizedUser(room.id, friendId);
            } catch (e) {
              print("從房間移除用戶授權錯誤: $e");
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(localizations?.friendRemoved ?? '好友已刪除')),
            );
          }
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}
