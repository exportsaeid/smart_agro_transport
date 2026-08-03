import 'package:flutter/material.dart';
import '../widgets/in_transit_widget.dart';
import '../widgets/cleared_widget.dart';
import 'iraqi_handover_screen.dart';  // اضافه کنید

class ClearanceScreen extends StatefulWidget {
  const ClearanceScreen({super.key});

  @override
  State<ClearanceScreen> createState() => _ClearanceScreenState();
}

class _ClearanceScreenState extends State<ClearanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final GlobalKey<State<InTransitWidget>> _inTransitKey = GlobalKey();
  final GlobalKey<State<ClearedWidget>> _clearedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _showToast(String message, {Color color = Colors.green}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('🛂 ترخیص مرز'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '🚚 در راه مرز'),
            Tab(text: '✅ ترخیص شده'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorWeight: 3,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              (_inTransitKey.currentState as dynamic)?.refreshData();
              (_clearedKey.currentState as dynamic)?.refreshData();
              _showToast('🔄 اطلاعات بروزرسانی شد', color: Colors.blue);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          InTransitWidget(
            key: _inTransitKey,
            onCleared: () {
              (_clearedKey.currentState as dynamic)?.refreshData();
            },
          ),
          ClearedWidget(key: _clearedKey),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}