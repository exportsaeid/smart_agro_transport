import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class CustomPersianDatePicker {
  static Future<String?> show(BuildContext context) async {
    Jalali selected = Jalali.now();
    int year = selected.year;
    int month = selected.month;
    int day = selected.day;

    final List<String> monthNames = [
      'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
      'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
    ];

    return showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final Jalali firstOfMonth = Jalali(year, month, 1);
            final int daysInMonth = firstOfMonth.monthLength;
            final int startDayOfWeek = firstOfMonth.weekDay;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                titlePadding: EdgeInsets.zero,
                contentPadding: const EdgeInsets.all(16),
                title: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'انتخاب تاریخ شمسی',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$day ${monthNames[month - 1]} $year',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                content: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // کنترل تغییر ماه و سال
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                if (month == 1) {
                                  year--;
                                  month = 12;
                                } else {
                                  month--;
                                }
                                int maxDays = Jalali(year, month, 1).monthLength;
                                if (day > maxDays) day = maxDays;
                              });
                            },
                          ),
                          Text(
                            '${monthNames[month - 1]} $year',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                if (month == 12) {
                                  year++;
                                  month = 1;
                                } else {
                                  month++;
                                }
                                int maxDays = Jalali(year, month, 1).monthLength;
                                if (day > maxDays) day = maxDays;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // روزهای هفته
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          Text('ش', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text('ی', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text('د', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text('س', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text('چ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text('پ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text('ج', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                      const Divider(),
                      // جدول روزها
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: (startDayOfWeek - 1) + daysInMonth,
                        itemBuilder: (context, index) {
                          if (index < startDayOfWeek - 1) {
                            return const SizedBox();
                          }
                          final int dayNum = index - (startDayOfWeek - 1) + 1;
                          final bool isSelected = (dayNum == day);

                          return InkWell(
                            onTap: () {
                              setState(() {
                                day = dayNum;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.green : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$dayNum',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('انصراف', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final formattedDate =
                          '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}';
                      Navigator.pop(context, formattedDate);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('تایید'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}