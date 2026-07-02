import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/backup/backup_crypto.dart';
import 'package:kakeibo_app/data/backup/backup_data.dart';

void main() {
  final crypto = BackupCrypto(pbkdf2Iterations: 1000); // テスト高速化

  test('encrypt -> decrypt round-trips the plaintext', () async {
    const plain = '{"formatVersion":1,"日本語":"含む🍙"}';
    final bytes = await crypto.encrypt(plain, 'correct horse battery');
    final back = await crypto.decrypt(bytes, 'correct horse battery');
    expect(back, plain);
  });

  test('same plaintext encrypts to different bytes (random salt/nonce)', () async {
    final a = await crypto.encrypt('secret', 'pass');
    final b = await crypto.encrypt('secret', 'pass');
    expect(a, isNot(equals(b)));
  });

  test('wrong passphrase -> BackupDecryptionError', () async {
    final bytes = await crypto.encrypt('secret', 'right');
    await expectLater(
      crypto.decrypt(bytes, 'wrong'),
      throwsA(isA<BackupDecryptionError>()),
    );
  });

  test('tampered ciphertext -> BackupDecryptionError', () async {
    final bytes = await crypto.encrypt('secret', 'pass');
    final tampered = Uint8List.fromList(bytes);
    tampered[tampered.length - 20] ^= 0xFF; // ciphertext末尾付近を反転
    await expectLater(
      crypto.decrypt(tampered, 'pass'),
      throwsA(isA<BackupDecryptionError>()),
    );
  });

  test('not an encrypted backup (bad magic / too short) -> BackupDecryptionError',
      () async {
    await expectLater(
      crypto.decrypt(Uint8List.fromList([1, 2, 3]), 'pass'),
      throwsA(isA<BackupDecryptionError>()),
    );
  });
}
