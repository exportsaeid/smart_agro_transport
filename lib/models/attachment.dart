class Attachment {
  int? id;
  int invoiceId;
  String fileName;
  String filePath;
  String fileType;

  Attachment({
    this.id,
    required this.invoiceId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
    };
  }

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'],
      invoiceId: map['invoice_id'],
      fileName: map['file_name'] ?? '',
      filePath: map['file_path'] ?? '',
      fileType: map['file_type'] ?? '',
    );
  }
}
