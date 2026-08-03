import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/backup_helper.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupHelper _backupHelper = BackupHelper();
  List<FileSystemEntity> _backupFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBackupList();
  }

  Future<void> _loadBackupList() async {
    setState(() => _isLoading = true);
    try {
      _backupFiles = await _backupHelper.getBackupList();
    } catch (e) {
      _showSnackBar('❌ خطا در بارگذاری لیست بکاپ‌ها: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // ========== ایجاد بکاپ جدید ==========
  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    try {
      final backupPath = await _backupHelper.createBackup();
      if (backupPath != null) {
        _showSnackBar('✅ بکاپ با موفقیت ایجاد شد!', Colors.green);
        _loadBackupList();
      } else {
        _showSnackBar('❌ خطا در ایجاد بکاپ!', Colors.red);
      }
    } catch (e) {
      _showSnackBar('❌ خطا در ایجاد بکاپ: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ========== بازگردانی از بکاپ درون‌برنامه ای ==========
  Future<void> _restoreBackup(String backupPath) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('⚠️ تأیید بازگردانی'),
        content: const Text('آیا از بازگردانی اطلاعات از این بکاپ مطمئن هستید؟\n\nتمام داده‌های فعلی پاک خواهند شد.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);

              final success = await _backupHelper.restoreBackup(backupPath);
              setState(() => _isLoading = false);

              if (!mounted) return;
              if (success) {
                _showSnackBar('✅ اطلاعات با موفقیت بازگردانی شد!', Colors.green);
                _loadBackupList();
              } else {
                _showSnackBar('❌ خطا در بازگردانی اطلاعات!', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('بله، بازگردانی کن'),
          ),
        ],
      ),
    );
  }

  // ========== حذف بکاپ ==========
  Future<void> _deleteBackup(String backupPath) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🗑️ حذف بکاپ'),
        content: const Text('آیا از حذف این فایل بکاپ مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _backupHelper.deleteBackup(backupPath);
              if (!mounted) return;
              if (success) {
                _showSnackBar('🗑️ فایل بکاپ حذف شد', Colors.orange);
                _loadBackupList();
              } else {
                _showSnackBar('❌ خطا در حذف فایل', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  // ========== بازگردانی از فایل خارجی (کاملاً تصحیح شده) ==========
  Future<void> _restoreFromExternalFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result == null) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('⚠️ تأیید بازگردانی'),
          content: Text('آیا از بازگردانی اطلاعات از فایل "${result.files.first.name}" مطمئن هستید؟\n\nتمام داده‌های فعلی پاک خواهند شد.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);

                final success = await _backupHelper.restoreBackup(filePath);
                setState(() => _isLoading = false);

                if (!mounted) return;
                if (success) {
                  _showSnackBar('✅ اطلاعات با موفقیت بازگردانی شد!', Colors.green);
                  _loadBackupList();
                } else {
                  _showSnackBar('❌ خطا در بازگردانی اطلاعات!', Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('بله، بازگردانی کن'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnackBar('❌ خطا در انتخاب فایل: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('💾 پشتیبان‌گیری و بازگردانی'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBackupList,
          ),
        ],
      ),
      body: Column(
        children: [
          // ====== دکمه‌های اصلی ======
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createBackup,
                    icon: const Icon(Icons.save, size: 20),
                    label: const Text('💾 ایجاد بکاپ', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _restoreFromExternalFile,
                    icon: const Icon(Icons.folder_open, size: 20),
                    label: const Text('📂 بازگردانی از فایل', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📋 لیست بکاپ‌ها',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_backupFiles.length} فایل',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // ====== لیست بکاپ‌ها ======
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _backupFiles.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _backupFiles.length,
              itemBuilder: (context, index) {
                final file = _backupFiles[index];
                final fileName = file.path.split(Platform.pathSeparator).last;
                final info = BackupHelper.getBackupInfo(file);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.storage, size: 32, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                info,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.restore, color: Colors.green),
                          onPressed: () => _restoreBackup(file.path),
                          tooltip: 'بازگردانی',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBackup(file.path),
                          tooltip: 'حذف',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.save, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '💾 هیچ بکاپی یافت نشد',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'برای ایجاد بکاپ، دکمه "ایجاد بکاپ" را بزنید',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}