import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:ui' as ui;
import '../database/database_helper.dart';
import '../models/profit_item.dart';
import '../utils/persian_date_helper.dart';

class ProfitReportPage extends StatefulWidget {
  const ProfitReportPage({super.key});

  @override
  State<ProfitReportPage> createState() => _ProfitReportPageState();
}

class _ProfitReportPageState extends State<ProfitReportPage> {
  List<ProfitItem> _allProfitItems = [];
  List<ProfitItem> _filteredItems = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  String? _fromDate;
  String? _toDate;

  static const Map<String, int> _monthNames = {
    'فروردین': 1,
    'اردیبهشت': 2,
    'خرداد': 3,
    'تیر': 4,
    'مرداد': 5,
    'شهریور': 6,
    'مهر': 7,
    'آبان': 8,
    'آذر': 9,
    'دی': 10,
    'بهمن': 11,
    'اسفند': 12,
  };

  int? _toComparable(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;

    try {
      String normalized = dateStr
          .replaceAll('۰', '0')
          .replaceAll('۱', '1')
          .replaceAll('۲', '2')
          .replaceAll('۳', '3')
          .replaceAll('۴', '4')
          .replaceAll('۵', '5')
          .replaceAll('۶', '6')
          .replaceAll('۷', '7')
          .replaceAll('۸', '8')
          .replaceAll('۹', '9')
          .trim();

      final slashParts = normalized.split(RegExp(r'[/\-.]'));
      if (slashParts.length >= 3) {
        final year = int.tryParse(slashParts[0].trim());
        final month = int.tryParse(slashParts[1].trim());
        final day = int.tryParse(slashParts[2].trim());
        if (year != null &&
            month != null &&
            day != null &&
            year >= 1300 &&
            year <= 1450 &&
            month >= 1 &&
            month <= 12 &&
            day >= 1 &&
            day <= 31) {
          return year * 10000 + month * 100 + day;
        }
      }

      for (final entry in _monthNames.entries) {
        if (normalized.contains(entry.key)) {
          final month = entry.value;
          final afterMonth = normalized.split(entry.key);
          final dayMatch =
          RegExp(r'(\d{1,2})\s*$').firstMatch(afterMonth[0].trim());
          final day =
          dayMatch != null ? int.tryParse(dayMatch.group(1)!) : null;
          final yearMatch = RegExp(r'(\d{4})')
              .firstMatch(afterMonth.length > 1 ? afterMonth[1] : '');
          final year =
          yearMatch != null ? int.tryParse(yearMatch.group(1)!) : null;
          if (year != null &&
              day != null &&
              year >= 1300 &&
              year <= 1450 &&
              day >= 1 &&
              day <= 31) {
            return year * 10000 + month * 100 + day;
          }
        }
      }

      final j = PersianDateHelper.parsePersianDate(dateStr);
      if (j != null) {
        return j.year * 10000 + j.month * 100 + j.day;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await DatabaseHelper.instance.getProfitReportData();
    if (mounted) {
      setState(() {
        _allProfitItems = list;
        _isLoading = false;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    final fromKey = _toComparable(_fromDate);
    final toKey = _toComparable(_toDate);

    setState(() {
      _filteredItems = _allProfitItems.where((item) {
        final matchText = query.isEmpty ||
            item.invoiceNumber.toLowerCase().contains(query) ||
            item.buyerName.toLowerCase().contains(query);

        if (!matchText) return false;

        if (fromKey == null && toKey == null) return true;

        final loadKey = _toComparable(item.loadDate);
        if (loadKey == null) return false;

        if (fromKey != null && toKey == null) {
          return loadKey >= fromKey;
        }
        if (fromKey == null && toKey != null) {
          return loadKey <= toKey;
        }

        final int f = fromKey as int;
        final int t = toKey as int;
        return loadKey >= f && loadKey <= t;
      }).toList();
    });
  }

  Future<void> _pickFromDate() async {
    final picked = await PersianDateHelper.pickDate(
      context,
      initialDateStr: _fromDate,
    );
    if (picked != null) {
      setState(() => _fromDate = picked);
      _applyFilters();
    }
  }

  Future<void> _pickToDate() async {
    final picked = await PersianDateHelper.pickDate(
      context,
      initialDateStr: _toDate,
    );
    if (picked != null) {
      setState(() => _toDate = picked);
      _applyFilters();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _applyFilters();
  }

  double get _totalProfit =>
      _filteredItems.fold(0.0, (sum, item) => sum + item.profit);

  String _dateFilterLabel() {
    if (_fromDate != null && _toDate != null) {
      return 'از $_fromDate تا $_toDate';
    }
    if (_fromDate != null) return 'از تاریخ: $_fromDate';
    if (_toDate != null) return 'تا تاریخ: $_toDate';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = intl.NumberFormat("#,###");
    final isProfit = _totalProfit >= 0;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          title: const Text(
            '📊 گزارش سود و زیان',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tahoma',
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '💰 جمع کل سود / زیان',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontFamily: 'Tahoma',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${currencyFormat.format(_totalProfit)} تومان',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isProfit
                            ? const Color(0xFF1B5E20)
                            : const Color(0xFFC62828),
                        fontFamily: 'Tahoma',
                      ),
                    ),
                    if (_fromDate != null || _toDate != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _dateFilterLabel(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2E7D32),
                            fontFamily: 'Tahoma',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                  Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.date_range,
                              size: 18, color: Color(0xFF2E7D32)),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'فیلتر تاریخ بارگیری',
                          style: TextStyle(
                            fontFamily: 'Tahoma',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const Spacer(),
                        if (_fromDate != null || _toDate != null)
                          TextButton(
                            onPressed: _clearDateFilter,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(40, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'پاک کردن',
                              style: TextStyle(
                                fontFamily: 'Tahoma',
                                fontSize: 12,
                                color: Color(0xFFC62828),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _dateChip(
                            label: 'از تاریخ',
                            value: _fromDate,
                            onTap: _pickFromDate,
                            onClear: _fromDate != null
                                ? () {
                              setState(() => _fromDate = null);
                              _applyFilters();
                            }
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dateChip(
                            label: 'تا تاریخ',
                            value: _toDate,
                            onTap: _pickToDate,
                            onClear: _toDate != null
                                ? () {
                              setState(() => _toDate = null);
                              _applyFilters();
                            }
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'فقط «از»، فقط «تا»، یا هر دو را انتخاب کنید',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontFamily: 'Tahoma',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                style: const TextStyle(fontFamily: 'Tahoma', fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'جستجو (شماره فاکتور، نام خریدار)...',
                  hintStyle: TextStyle(
                    fontFamily: 'Tahoma',
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                  prefixIcon:
                  const Icon(Icons.search, color: Color(0xFF43A047)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFC8E6C9)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                    const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2E7D32),
                ),
              )
                  : _filteredItems.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 56, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'موردی برای نمایش وجود ندارد',
                      style: TextStyle(
                        fontFamily: 'Tahoma',
                        color: Colors.grey[600],
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تحویل به خریدار ثبت شود یا فیلتر را تغییر دهید',
                      style: TextStyle(
                        fontFamily: 'Tahoma',
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return _buildProfitCard(item, currencyFormat);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateChip({
    required String label,
    required String? value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: hasValue ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? const Color(0xFF81C784) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: hasValue ? const Color(0xFF2E7D32) : Colors.grey[500],
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontFamily: 'Tahoma',
                    ),
                  ),
                  Text(
                    hasValue ? value! : 'انتخاب کنید',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                      hasValue ? FontWeight.bold : FontWeight.normal,
                      color: hasValue
                          ? const Color(0xFF1B5E20)
                          : Colors.grey[500],
                      fontFamily: 'Tahoma',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 15, color: Colors.grey[500]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitCard(ProfitItem item, intl.NumberFormat format) {
    final isProfit = item.profit >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      decoration: BoxDecoration(
        color: isProfit
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isProfit
              ? const Color(0xFFA5D6A7)
              : const Color(0xFFEF9A9A),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isProfit ? Colors.green : Colors.red).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isProfit
                  ? const Color(0xFFC8E6C9)
                  : const Color(0xFFFFCDD2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '🧾 فاکتور #${item.invoiceNumber}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isProfit
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFFB71C1C),
                      fontFamily: 'Tahoma',
                    ),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '👤 ${item.buyerName}',
                    style: const TextStyle(
                      color: Color(0xFF455A64),
                      fontSize: 12,
                      fontFamily: 'Tahoma',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        '📅 تاریخ بارگیری',
                        item.loadDate.isNotEmpty ? item.loadDate : '—',
                      ),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        '📦 تاریخ تحویل به خریدار',
                        item.deliveryDate.isNotEmpty
                            ? item.deliveryDate
                            : '—',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildMoneyRow(
                    '📦 مبلغ کالاها', format.format(item.invoiceAmount)),
                _buildMoneyRow('➕ هزینه متفرقه', format.format(item.miscCost)),
                _buildMoneyRow(
                    '🚚 کرایه ایرانی', format.format(item.iranianTransport)),
                _buildMoneyRow(
                    '🛂 ترخیص ایران', format.format(item.iranianClearance)),
                _buildMoneyRow(
                    '🇮🇶 هزینه عراقی', format.format(item.iraqiTotalCost)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFE0E0E0)),
                ),
                _buildMoneyRow(
                  '💰 واریزی خریدار',
                  format.format(item.receivedAmount),
                  valueColor: const Color(0xFF2E7D32),
                  isBold: true,
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isProfit
                          ? [const Color(0xFF2E7D32), const Color(0xFF43A047)]
                          : [const Color(0xFFC62828), const Color(0xFFE53935)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'سود خالص این فاکتور',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontFamily: 'Tahoma',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isProfit ? "+" : ""}${format.format(item.profit)} تومان',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Tahoma',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF546E7A),
            fontFamily: 'Tahoma',
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF263238),
              fontFamily: 'Tahoma',
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  Widget _buildMoneyRow(
      String label,
      String value, {
        Color? valueColor,
        bool isBold = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF455A64),
              fontFamily: 'Tahoma',
            ),
          ),
          Text(
            '$value تومان',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? const Color(0xFF263238),
              fontFamily: 'Tahoma',
            ),
          ),
        ],
      ),
    );
  }
}