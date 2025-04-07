import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Thông báo',
          style: TextStyle(
            fontFamily: 'KohSantepheap',
            fontSize: 20.0,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: Handle edit action
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            color: Colors.grey,
            thickness: 0.5,
            height: 0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20.0),

            // Thông báo 1
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_fire_department_outlined, color: Colors.orange),
                  SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      'Bạn sắp để mất chuỗi 2 ngày streak.',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            // Thông báo 2
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(FontAwesomeIcons.fire, color: Color(0xFFD36EE5)),
                  SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      "Bạn đang có chuỗi 4 ngày học tập!",
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            // Nếu không có thông báo nào khác
            const Expanded(
              child: Center(
                child: Text(
                  'Không có thông báo nào khác.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
