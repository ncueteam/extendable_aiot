import 'package:flutter/material.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/models/abstract/room_model.dart';

Future<void> showEditRoomDialog(BuildContext context, RoomModel room) async {
  final localizations = AppLocalizations.of(context);
  final TextEditingController nameController = TextEditingController(
    text: room.name,
  );

  return showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(localizations?.editRoom ?? '編輯房間'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: localizations?.roomName ?? '房間名稱',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations?.cancel ?? '取消'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  room.name = nameController.text;
                  await room.updateRoom();
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(localizations?.confirm ?? '確認'),
            ),
          ],
        ),
  );
}

Future<void> showDeleteRoomDialog(
  BuildContext context,
  RoomModel room, {
  Function? onDeleted,
}) async {
  final localizations = AppLocalizations.of(context);

  return showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(localizations?.confirmDelete ?? '確認刪除'),
          content: Text('確定要刪除房間 "${room.name}" 嗎？此操作無法撤銷，且會同時刪除所有關聯裝置。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations?.cancel ?? '取消'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                try {
                  await room.deleteRoom();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('房間已刪除')));
                    onDeleted?.call();
                  }
                } catch (e) {
                  print('刪除房間錯誤: $e');
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('刪除房間失敗: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(localizations?.delete ?? '刪除'),
            ),
          ],
        ),
  );
}
