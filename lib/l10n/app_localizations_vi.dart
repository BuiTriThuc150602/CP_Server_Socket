// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Socket Testing Tools';

  @override
  String get chooseModule => 'Chọn một module kiểm thử desktop để bắt đầu.';

  @override
  String get system => 'Hệ thống';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get carParkingTitle => 'Mô phỏng Device Gateway CarParking';

  @override
  String get carParkingShort => 'CarParking';

  @override
  String get carParkingDescription =>
      'Mô phỏng TCP Device Gateway cho CarParking_Techpro_Client.';

  @override
  String get tcpLabTitle => 'TCP Socket Lab';

  @override
  String get tcpLabShort => 'TCP Lab';

  @override
  String get tcpLabDescription =>
      'Không gian kiểm thử TCP client/server tổng quát.';

  @override
  String get webSocketTitle => 'WebSocket Lab';

  @override
  String get webSocketShort => 'WebSocket';

  @override
  String get webSocketDescription => 'Bàn thử gửi/nhận WebSocket realtime.';

  @override
  String get serialTitle => 'Serial/COM Lab';

  @override
  String get serialShort => 'Serial';

  @override
  String get serialDescription => 'Bàn thử cổng serial cho desktop.';

  @override
  String get bridgeTitle => 'Protocol Bridge';

  @override
  String get bridgeShort => 'Bridge';

  @override
  String get bridgeDescription =>
      'Công cụ bridge TCP, Serial và WebSocket trong tương lai.';

  @override
  String get payloadStudioTitle => 'Payload Studio / Converter';

  @override
  String get payloadStudioShort => 'Payloads';

  @override
  String get payloadStudioDescription =>
      'Không gian chuyển đổi JSON, text, binary và checksum.';

  @override
  String get apiLabTitle => 'API Lab';

  @override
  String get apiLabShort => 'API';

  @override
  String get apiLabDescription =>
      'Không gian kiểm thử HTTP/API với collections, environments, variables và import/export.';

  @override
  String get start => 'Bắt đầu';

  @override
  String get stop => 'Dừng';

  @override
  String get restart => 'Khởi động lại';

  @override
  String get connect => 'Kết nối';

  @override
  String get disconnect => 'Ngắt kết nối';

  @override
  String get send => 'Gửi';

  @override
  String get import => 'Nhập';

  @override
  String get export => 'Xuất';

  @override
  String get delete => 'Xoá';

  @override
  String get duplicate => 'Nhân bản';

  @override
  String get enable => 'Bật';

  @override
  String get disable => 'Tắt';

  @override
  String get settings => 'Cài đặt';

  @override
  String get clear => 'Xoá';

  @override
  String get copy => 'Sao chép';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get console => 'Console';

  @override
  String get terminal => 'Terminal';
}
