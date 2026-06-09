# fake_frame_decryptor

## 概述

`FakeFrameDecryptor` 是一个仅用于测试的 `FrameDecryptorInterface` 假实现。它使用简单的单字节密钥和固定后缀字节模拟帧解密过程，用于验证 WebRTC 帧加密/解密核心链路的正确性。

## 头文件接口 (.h)

### `FakeFrameDecryptor` 类

继承自 `FrameDecryptorInterface`：

- **`FakeFrameDecryptor(fake_key = 0xAA, expected_postfix_byte = 255)`** — 构造，设置密钥和预期后缀
- **`Decrypt(media_type, csrcs, additional_data, encrypted_frame, frame)`** — 解密逻辑
- **`GetMaxPlaintextByteSize(media_type, encrypted_frame_size)`** — 返回最大明文大小（密文大小减 1）
- **`SetFakeKey(key)` / `GetFakeKey()`** — 设置/获取密钥
- **`SetExpectedPostfixByte(byte)` / `GetExpectedPostfixByte()`** — 设置/获取预期后缀字节
- **`SetFailDecryption(bool)`** — 强制解密失败

### 状态枚举

`FakeDecryptStatus`：
- `OK = 0` — 成功
- `FORCED_FAILURE = 1` — 强制失败
- `INVALID_POSTFIX = 2` — 后缀字节不匹配

## 实现文件 (.cc)

### 解密逻辑

1. 如果 `fail_decryption_` 为 true，返回 `kFailedToDecrypt`。
2. 检查 `frame.size() + 1 == encrypted_frame.size()`（密文比明文多一个后缀字节）。
3. 对每个明文字节执行 XOR 操作：`frame[i] = encrypted_frame[i] ^ fake_key_`。
4. 检查最后一个密文字节是否等于 `expected_postfix_byte_`，不匹配则返回失败。
5. 成功返回 `Status::kOk` 和明文大小。

### FakeFrameEncryptor 的配对

`FakeFrameEncryptor` 执行反向操作：对每个有效载荷字节 XOR 密钥，并在末尾添加后缀字节。

## 学习扩展

- **FrameEncryptorInterface / FrameDecryptorInterface**: WebRTC 的可插入帧加密/解密接口，用于端到端加密（E2EE）场景。
- **XOR 加密**: 最简单的一种对称加密，可用于验证框架功能，不应用于实际安全场景。

## 设计模式

- **假对象模式（Fake Object）** — 提供一个轻量级的模拟实现，用于测试核心链路的正确性。
- **策略模式（可插入加密）** — 通过接口实现了可替换的加密策略。
