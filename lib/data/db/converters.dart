import 'package:drift/drift.dart';
import '../../domain/money/civil_date.dart';

/// CivilDate を TEXT 'YYYY-MM-DD' として保存する drift TypeConverter。
/// ゼロ埋めISOなので辞書順＝時系列順となり、月次範囲クエリを文字列比較で行える。
class CivilDateConverter extends TypeConverter<CivilDate, String> {
  const CivilDateConverter();

  @override
  CivilDate fromSql(String fromDb) => CivilDate.parse(fromDb);

  @override
  String toSql(CivilDate value) => value.toIso();
}
