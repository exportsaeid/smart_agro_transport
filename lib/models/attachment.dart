class AttachmentItem {
  int? id;
  String name;
  String path;
  int size;
  bool isSaved;
  String? fileType;

  AttachmentItem({
    this.id,
    required this.name,
    required this.path,
    this.size = 0,
    this.isSaved = false,
    this.fileType,
  });

  AttachmentItem copyWith({
    int? id,
    String? name,
    String? path,
    int? size,
    bool? isSaved,
    String? fileType,
  }) {
    return AttachmentItem(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      isSaved: isSaved ?? this.isSaved,
      fileType: fileType ?? this.fileType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_name': name,
      'file_path': path,
      'file_type': fileType,
    };
  }

  factory AttachmentItem.fromMap(Map<String, dynamic> map) {
    return AttachmentItem(
      id: map['id'],
      name: map['file_name'] ?? '',
      path: map['file_path'] ?? '',
      fileType: map['file_type'] ?? '',
      isSaved: true,
    );
  }
}