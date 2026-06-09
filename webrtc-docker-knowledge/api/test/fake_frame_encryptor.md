# fake_frame_encryptor

## 概述

`FakeFrameEncryptor` 是一个仅用于测试的 `FrameEncryptorInterface` 假实现。与 `FakeFrameDecryptor` 配对使用，使用相同的单字节密钥和固定后缀字节机制模拟帧加密过程。

## 头文件接口 (.h)

### `FakeFrameEncryptor` 类

继承自 `RefCountedObject<FrameEncryptorInterface>`：

- **`FakeFrameEncryptor(fake_key = 0xAA, postfix_byte = 255)`** — 构造，设置密钥和后缀字节
- **`Encrypt(media_type, ssrc, additional_data, frame, encrypted_frame, bytes_written)`** — 加密逻辑
- **`GetMaxCiphertextByteSize(media_type, frame_size)`** — 返回最大密文大小（明文大小加 1）
- **`SetFakeKey(key)` / `GetFakeKey()`** — 设置/获取密钥
- **`SetPostfixByte(byte)` / `GetPostfixByte()`** — 设置/获取后缀字节
- **`SetFailEncryption(bool)`** — 强制加密失败

### 状态枚举

`FakeEncryptionStatus`：
- `OK = 0` — 成功
- `FORCED_FAILURE = 1` — 强制失败

## 实现文件 (.cc)

### 加密逻辑

1. 如果 `fail_encryption_` 为 true，返回 `FORCED_FAILURE`。
2. 检查 `frame.size() + 1 == encrypted_frame.size()`。
3. 对每个明文字节执行 XOR 操作。
4. 在末尾写入后缀字节。
5. 设置 `*bytes_written` 为密文大小。

## 学习扩展

- **RefCountedObject**: WebRTC 的引用计数包装器，`FakeFrameEncryptor` 继承它来支持引用计数生命周期管理。
- **端到端加密**: WebRTC 支持通过 `FrameEncryptorInterface` 和 `FrameDecryptorInterface` 插入自定义的端到端加密方案。

## 设计模式

- **假对象模式（Fake Object）** — 简化测试的假实现。
