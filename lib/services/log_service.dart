import 'package:hive/hive.dart';
import '../models/update_log.dart';
import '../models/price_update_log.dart';

class LogService {
  static const String _summaryBox = "update_logs";
  static const String _detailsBox = "price_update_logs";

  
  static Future<void> addUpdateLog(UpdateLogSummary log) async {
    final box = Hive.box<UpdateLogSummary>(_summaryBox);
    await box.add(log);
  }

 
  static List<UpdateLogSummary> getUpdateLogs() {
    final box = Hive.box<UpdateLogSummary>(_summaryBox);
    return box.values.toList();
  }

  static Future<void> addPriceUpdateLog(PriceUpdateLog log) async {
    final box = Hive.box<PriceUpdateLog>(_detailsBox);
    await box.add(log);
  }

  static List<PriceUpdateLog> getPriceUpdateLogs() {
    final box = Hive.box<PriceUpdateLog>(_detailsBox);
    return box.values.toList();
  }
}






