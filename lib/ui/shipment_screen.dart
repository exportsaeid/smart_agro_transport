import 'package:flutter/material.dart';
import '../widgets/ready_invoices_widget.dart';
import '../widgets/completed_shipments_widget.dart';

class ShipmentScreen extends StatefulWidget {
  const ShipmentScreen({super.key});

  @override
  State<ShipmentScreen> createState() => _ShipmentScreenState();
}

class _ShipmentScreenState extends State<ShipmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ====== اصلاح: استفاده از State به جای State خاص ======
  final GlobalKey<State<ReadyInvoicesWidget>> _readyKey = GlobalKey();
  final GlobalKey<State<CompletedShipmentsWidget>> _completedKey = GlobalKey();

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
        title: const Text('🚛📋 مدیریت بارگیری'),
        backgroundColor: const Color(0xFF1976D2),
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
            Tab(text: '📋 فاکتورهای آماده'),
            Tab(text: '🚛 بارگیری‌ها'),
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
              // ====== اصلاح: cast کردن به State و صدا زدن متد ======
              (_readyKey.currentState as dynamic)?.refreshData();
              (_completedKey.currentState as dynamic)?.refreshData();
              _showToast('🔄 اطلاعات بروزرسانی شد', color: Colors.blue);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ReadyInvoicesWidget(
            key: _readyKey,
            onShipmentCreated: (_) {
              (_completedKey.currentState as dynamic)?.refreshData();
            },
          ),
          CompletedShipmentsWidget(key: _completedKey),
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