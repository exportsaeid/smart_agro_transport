import 'package:flutter/material.dart';

class TableHeaderCell extends StatelessWidget {
  final String text;
  final double width;
  const TableHeaderCell({super.key, required this.text, required this.width});
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width, 
      child: Text(
        text, 
        textAlign: TextAlign.center, 
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
      )
    );
  }
}

class TableDataCell extends StatelessWidget {
  final String text;
  final double width;
  final Color? color;
  final bool isBold;
  const TableDataCell({super.key, required this.text, required this.width, this.color, this.isBold = false});
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width, 
      child: Text(
        text, 
        textAlign: TextAlign.center, 
        style: TextStyle(
          color: color, 
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal
        ), 
        maxLines: 1, 
        overflow: TextOverflow.ellipsis
      )
    );
  }
}
