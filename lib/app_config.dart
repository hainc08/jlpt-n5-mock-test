/// Cấu hình của từng app (mỗi cấp N5…N1 một app), truyền lúc build bằng
/// `--dart-define-from-file=apps/<app>/config.json`.
///
/// Không truyền gì thì mặc định là app N5.
class AppConfig {
  static const id = String.fromEnvironment('APP', defaultValue: 'n5');
  static const level = String.fromEnvironment('LEVEL', defaultValue: 'N5');
  static const name = String.fromEnvironment('APP_NAME', defaultValue: 'JLPT N5 Thi Thử');
  static const version = String.fromEnvironment('VERSION', defaultValue: '1.0.0');
}
