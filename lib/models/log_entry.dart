class LogEntry {
  final int? id;                  
  final String productName;      
  final String variantTitle;      
  final double oldPrice;          
  final double newPrice;          
  final String timestamp;         

  LogEntry({
    this.id,
    required this.productName,
    required this.variantTitle,
    required this.oldPrice,
    required this.newPrice,
    required this.timestamp,
  });


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productName': productName,
      'variantTitle': variantTitle,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'timestamp': timestamp,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id'],
      productName: map['productName'],
      variantTitle: map['variantTitle'],
      oldPrice: map['oldPrice'],
      newPrice: map['newPrice'],
      timestamp: map['timestamp'],
    );
  }
}