import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'backup_data.dart';

/// バックアップJSONのパスフレーズ暗号化。
/// 形式: "KKBK1"(5) + salt(16) + nonce(12) + ciphertext(n) + mac(16)
/// 鍵導出: PBKDF2-HMAC-SHA256 / 暗号: AES-256-GCM（MACで改ざん検知）
class BackupCrypto {
  static const _magic = 'KKBK1';
  static const _saltLength = 16;
  static const _nonceLength = 12;
  static const _macLength = 16;

  final int pbkdf2Iterations;
  BackupCrypto({this.pbkdf2Iterations = 200000});

  AesGcm get _aes => AesGcm.with256bits();

  Future<SecretKey> _deriveKey(String passphrase, List<int> salt) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: pbkdf2Iterations,
      bits: 256,
    );
    return pbkdf2.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  Future<Uint8List> encrypt(String plaintext, String passphrase) async {
    // salt(16バイト)を毎回ランダム生成。nonceは _aes.encrypt が自動生成し box.nonce に入る。
    final saltBytes = SecretKeyData.random(length: _saltLength).bytes;
    final key = await _deriveKey(passphrase, saltBytes);
    final box = await _aes.encrypt(utf8.encode(plaintext), secretKey: key);
    // box.concatenation() = nonce + cipherText + mac
    final out = BytesBuilder();
    out.add(ascii.encode(_magic));
    out.add(saltBytes);
    out.add(box.concatenation());
    return out.toBytes();
  }

  Future<String> decrypt(Uint8List data, String passphrase) async {
    final headerLen = _magic.length + _saltLength;
    final minLen = headerLen + _nonceLength + _macLength;
    if (data.length < minLen) {
      throw BackupDecryptionError('暗号化バックアップとして短すぎます');
    }
    final magic = ascii.decode(data.sublist(0, _magic.length), allowInvalid: true);
    if (magic != _magic) {
      throw BackupDecryptionError('暗号化バックアップのファイルではありません');
    }
    final salt = data.sublist(_magic.length, headerLen);
    final body = data.sublist(headerLen);
    final key = await _deriveKey(passphrase, salt);
    final box = SecretBox.fromConcatenation(
      body,
      nonceLength: _nonceLength,
      macLength: _macLength,
    );
    try {
      final clear = await _aes.decrypt(box, secretKey: key);
      return utf8.decode(clear);
    } on SecretBoxAuthenticationError {
      throw BackupDecryptionError('パスフレーズが違うか、データが破損しています');
    }
  }
}
