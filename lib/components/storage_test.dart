import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageTestWidget extends StatefulWidget {
  const StorageTestWidget({super.key});

  @override
  State<StorageTestWidget> createState() => _StorageTestWidgetState();
}

class _StorageTestWidgetState extends State<StorageTestWidget> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? _downloadUrl;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    try {
      // 創建一個唯一的檔案名
      String fileName = 'images/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 上傳檔案
      await _storage.ref(fileName).putFile(_image!);

      // 取得下載網址
      String downloadUrl = await _storage.ref(fileName).getDownloadURL();

      setState(() {
        _downloadUrl = downloadUrl;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('上傳成功！')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('上傳失敗：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_image != null)
              Image.file(
                _image!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('選擇圖片'),
                ),
                ElevatedButton(
                  onPressed: _image != null ? _uploadImage : null,
                  child: const Text('上傳圖片'),
                ),
              ],
            ),
            if (_downloadUrl != null) ...[
              const SizedBox(height: 16),
              Text('下載網址：$_downloadUrl'),
            ],
          ],
        ),
      ),
    );
  }
}
