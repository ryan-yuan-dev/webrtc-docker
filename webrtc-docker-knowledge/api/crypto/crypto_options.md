# crypto_options

## 概述

`crypto_options` 模块定义了 WebRTC 本地（native）API 中的加密配置选项。该选项通过 `PeerConnectionFactoryInterface::Options` 传入，用于控制 DTLS-SRTP 加密套件选择、FrameEncryptor/FrameDecryptor 帧加密要求、以及 DTLS 握手阶段的临时密钥交换密码组（Ephemeral Key Exchange Cipher Groups）。

此模块是 WebRTC 安全层的核心配置入口，直接影响媒体流的加密强度、兼容性和性能。

## 头文件接口 (.h)

### `CryptoOptions` 结构体

- **`NoGcm()`** — 静态工厂方法，返回禁用 GCM 加密套件的 `CryptoOptions` 实例。
- **`GetSupportedDtlsSrtpCryptoSuites()`** — 基于当前配置，返回支持的 DTLS-SRTP 加密套件列表（按优先级排序）。
- **`operator==` / `operator!=`** — 比较两个 `CryptoOptions` 是否相等。

#### 内部嵌套结构：`Srtp`

SRTP 相关的 Peer Connection 加密选项：

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `enable_gcm_crypto_suites` | bool | true | 启用 RFC 7714 GCM 加密套件，需双方同时启用 |
| `enable_aes128_sha1_32_crypto_cipher` | bool | false | 启用潜在不安全的 kSrtpAes128CmSha1_32 密码，节省每包字节 |
| `enable_aes128_sha1_80_crypto_cipher` | bool | true | 最常用密码，可禁用用于测试 |
| `enable_encrypted_rtp_header_extensions` | bool | true | 启用 RFC 6904 RTP 头部扩展加密，需 field trial `kWebRtcEncryptedRtpHeaderExtensions` |

#### 内部嵌套结构：`SFrame`

FrameEncryptor/FrameDecryptor 相关选项：

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `require_frame_encryption` | bool | false | 为 true 时，所有 RtpSender 必须挂载 FrameEncryptor，所有 RtpReceiver 必须挂载 FrameDecryptor |

#### 内部嵌套类：`EphemeralKeyExchangeCipherGroups`

DTLS 握手阶段临时密钥交换的密码组配置：

- **`kSECP224R1` / `kSECP256R1` / `kSECP384R1` / `kSECP521R1`** — 椭圆曲线组常量（RFC 8422 Section 5.1.1）。
- **`kX25519`** — Curve25519 组。
- **`kX25519_MLKEM768`** — 后量子密码混合组（X25519 + ML-KEM 768）。
- **`GetSupported()`** — 返回当前 SSL 栈支持的所有密码组。
- **`GetName(uint16_t group_id)`** — 返回密码组的可读名称。
- **`GetEnabled()`** — 获取当前启用的密码组列表。
- **`SetEnabled()`** — 设置启用的密码组。
- **`AddFirst(uint16_t group)`** — 将指定组移到列表首位（如果已存在则先移除再插入）。
- **`Update()`** — 基于 field trials 更新密码组列表，并可选择性禁用某些组。

## 实现文件 (.cc)

### 关键实现逻辑

**`NoGcm()`**: 创建一个默认 `CryptoOptions` 实例，仅将 `srtp.enable_gcm_crypto_suites` 设置为 `false`。用于需要禁用 GCM 的场景（如兼容性原因）。

**`GetSupportedDtlsSrtpCryptoSuites()`**: 按优先级构建加密套件列表：
1. 如果启用了 `aes128_sha1_32`，优先添加（默认禁用，因其安全性较低）。
2. 如果启用了 `aes128_sha1_80`，添加（默认启用，RFC 要求必须支持的套件）。
3. 如果启用了 GCM，在列表末尾添加 `kSrtpAeadAes256Gcm` 和 `kSrtpAeadAes128Gcm`（GCM 加密包更大，非首选）。
4. 通过 `RTC_CHECK` 确保列表非空，否则触发断言失败。

**`operator==`**: 使用 `static_assert` 校验新增字段是否同步更新了比较逻辑，这是一种编译期安全检查模式。

**`EphemeralKeyExchangeCipherGroups` 构造函数**: 委托给 `SSLStreamAdapter::GetDefaultEphemeralKeyExchangeCipherGroups` 获取默认启用的密码组。

**`AddFirst()`**: 先使用 `std::erase` 移除已存在的同名组（避免重复），再插入到列表最前面。

**`Update()`**:
1. 获取 field trials 定义的默认密码组。
2. 如果提供了 `disabled_groups`，从默认列表和当前列表中移除被禁用的组。
3. 将默认组中尚不在当前列表中的组添加到最前面。
4. 将当前组中尚未重新添加的组追加到末尾（保持存在的组不被丢弃）。

### 单元测试 (`crypto_options_unittest.cc`)

- **`GetSupported`** — 验证所有支持的密码组（通过 SSL 宏定义检查）都包含在 `GetSupported()` 返回值中。
- **`GetEnabled`** — 验证默认启用的密码组列表与预期一致（X25519 + SECP256R1 + SECP384R1）。
- **`SetEnabled`** — 验证 `SetEnabled` 成功后 `GetEnabled` 返回相同结果。
- **`AddFirst`** — 验证 `AddFirst` 将指定组移到首位，且不产生重复。
- **`Update`** — 验证通过 field trial `WebRTC-EnableDtlsPqc/Enabled/` 启用后量子密码组、禁用 X25519 后，启用列表的正确性。
- **`CopyCryptoOptions`** — 验证 `CryptoOptions` 支持拷贝构造和拷贝赋值。

## 学习扩展

- **DTLS-SRTP**: WebRTC 使用 DTLS 握手协商 SRTP 密钥，加密套件的选择直接影响媒体流的安全性。了解 SRTP 加密套件格式（如 `kSrtpAes128CmSha1_80` 的含义）。
- **GCM vs. 非 GCM**: GCM（Galois/Counter Mode）提供认证加密，但增加包大小。WebRTC 推荐在两者都支持时优先使用非 GCM 套件。
- **RFC 7714** — AES-GCM 用于 SRTP。
- **RFC 6904** — RTP 头部扩展加密。
- **后量子密码学**: `kX25519_MLKEM768` 是 WebRTC 对后量子密码学的支持，ML-KEM（CRYSTALS-Kyber）已被 NIST 标准化。
- **Elliptic Curve Groups**: 椭圆曲线在 DTLS 握手中的角色与选择策略。
- **static_assert + sizeof 技巧**: 用于捕获结构体字段变更但比较操作未同步更新的编译期检查模式。

## 设计模式

- **工厂方法模式** — `NoGcm()` 作为静态工厂方法，提供预设配置的便捷创建方式。
- **值对象模式** — `CryptoOptions` 是一个不可变（通过 const 方法使用）的配置值对象，支持拷贝和比较。
- **策略模式** — 加密套件的选择和排序逻辑封装在 `GetSupportedDtlsSrtpCryptoSuites()` 中，可基于不同的配置生成不同的策略。
- **编译时断言** — 使用 `static_assert` 与 `sizeof` 确保结构体扩展时关联方法同步更新。
