import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SendRequestButton extends StatefulWidget {
  const SendRequestButton({Key? key}) : super(key: key);

  @override
  State<SendRequestButton> createState() => _SendRequestButtonState();
}

class _SendRequestButtonState extends State<SendRequestButton> {
  bool _isLoading = false;
  final _contentController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _sendEmail(String subject, String content) async {
    if (user?.email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Bạn cần đăng nhập để gửi yêu cầu'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    final emailUsername = dotenv.env['EMAIL_USERNAME'];
    final emailPassword = dotenv.env['EMAIL_PASSWORD'];

    if (emailUsername == null || emailPassword == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Lỗi cấu hình email. Vui lòng liên hệ admin.'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    final smtpServer = gmail(emailUsername, emailPassword);
    
    final message = Message()
      ..from = Address(emailUsername, 'Quản lý trang trại')
      ..recipients.add(user!.email!)
      ..subject = subject
      ..html = '''
        <h2>Yêu cầu từ người dùng</h2>
        <p><strong>Loại yêu cầu:</strong> $subject</p>
        <p><strong>Email người gửi:</strong> ${user!.email}</p>
        <p><strong>Thời gian gửi:</strong> ${DateTime.now().toString()}</p>
        <p><strong>Nội dung:</strong></p>
        <p>$content</p>
        <br>
        <p>Chúng tôi đã nhận được yêu cầu của bạn và sẽ phản hồi trong thời gian sớm nhất.</p>
        <p>Thời gian phản hồi dự kiến: 24-48 giờ làm việc.</p>
        <br>
        <p><i>Đây là email tự động, vui lòng không trả lời email này.</i></p>
        <p><strong>Quản lý trang trại</strong></p>
      ''';

    try {
      await send(message, smtpServer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Yêu cầu đã được gửi thành công!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Có lỗi xảy ra khi gửi yêu cầu. Vui lòng thử lại.'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showContentDialog(String title, String subject, IconData icon) async {
    if (user?.email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Bạn cần đăng nhập để gửi yêu cầu'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    _contentController.clear();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: const Color(0xFF64B5F6)),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chi tiết yêu cầu:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF64B5F6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF64B5F6), width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Email nhận phản hồi: ${user!.email}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64B5F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Gửi yêu cầu',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result == true && _contentController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      await _sendEmail(subject, _contentController.text);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showRequestMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Chọn loại yêu cầu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildRequestTile(
              icon: Icons.question_answer,
              title: 'Gửi câu hỏi',
              subtitle: 'Đặt câu hỏi về sản phẩm hoặc dịch vụ',
              onTap: () {
                Navigator.pop(context);
                _showContentDialog(
                  'Gửi câu hỏi',
                  'Câu hỏi từ người dùng',
                  Icons.question_answer,
                );
              },
            ),
            _buildRequestTile(
              icon: Icons.delete_forever,
              title: 'Yêu cầu xóa tài khoản',
              subtitle: 'Gửi yêu cầu xóa tài khoản của bạn',
              onTap: () {
                Navigator.pop(context);
                _showContentDialog(
                  'Yêu cầu xóa tài khoản',
                  'Yêu cầu xóa tài khoản',
                  Icons.delete_forever,
                );
              },
            ),
            _buildRequestTile(
              icon: Icons.bug_report,
              title: 'Báo lỗi ứng dụng',
              subtitle: 'Báo cáo các vấn đề kỹ thuật',
              onTap: () {
                Navigator.pop(context);
                _showContentDialog(
                  'Báo lỗi ứng dụng',
                  'Báo cáo lỗi ứng dụng',
                  Icons.bug_report,
                );
              },
            ),
            _buildRequestTile(
              icon: Icons.mail,
              title: 'Gửi yêu cầu khác',
              subtitle: 'Các yêu cầu không thuộc các mục trên',
              onTap: () {
                Navigator.pop(context);
                _showContentDialog(
                  'Gửi yêu cầu khác',
                  'Yêu cầu khác từ người dùng',
                  Icons.mail,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF64B5F6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF64B5F6)),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF64B5F6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.send,
          color: Color(0xFF64B5F6),
        ),
      ),
      title: const Text('Gửi yêu cầu'),
      subtitle: const Text('Hỗ trợ, báo lỗi, câu hỏi và yêu cầu khác'),
      onTap: _isLoading ? null : _showRequestMenu,
    );
  }
}